-- Xbox Original modchip code for 1MB w/ write protect
-- Copyright (C) 2019  Benjamin Fiset-Deschênes

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.

-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.


-- Interface Xbox LPC to SST49LF080A flash device
-- Optional external physical switch between H0 pad and GND to inhibit write
-- No switch on H0 pad = write always enabled
-- Design requires pull-ups on "pin_pad_bt" and "pin_pad_h0" at least
-- Internal pull-ups of LC4032V are sufficient in a normal Xbox environment

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


-- ----------------------------------------
entity entity_lpcmod is
-- ----------------------------------------
    port (
        pin_xbox_n_lrst     : in    std_logic;                      -- Xbox-side Reset signal
        pin_xbox_lclk       : in    std_logic;                      -- Xbox-side CLK, goes to flash chip too
        pin_pad_bt          : in    std_logic;                      -- Xbox power button. Labeled "BT" on silkscreen, near unrouted LCD pad array.
        pin_pad_h0          : in    std_logic;                      -- Unused pad? Labeled "H0" on silkscreen, near D0 pad. Will be used for flash bank switch (2 * 512KB).
        pout_flash_lframe   : out   std_logic;                      -- Only goes to flash chip. Is generated by code logic.
        pinout4_xbox_lad    : inout std_logic_vector(3 downto 0);   -- Xbox-side LPC IO
        pinout4_flash_lad   : inout std_logic_vector(3 downto 0);   -- Flash-side LPC IO
        pinout_pad_d0       : inout std_logic ;                     -- D0 control on Xbox motherbord. Useful on all motherboards but 1.6(b) should really USE L1 instead!
        pinout_pad_x        : inout std_logic;                      -- Supports D0 to sink in more current.
        pinout_pad_l1       : inout std_logic                       -- LFRAME control on the Motherboard. Useful only on 1.6(b)
    );
end entity_lpcmod;

-- ----------------------------------------
architecture arch_lpcmod of entity_lpcmod is
-- ----------------------------------------
--**+ constants +***

    constant c_DEVICE_ENABLED: std_logic := '0';
    constant c_DEVICE_DISABLED: std_logic := '1';
    
    constant c_LAD_IDLE_PATTERN: std_Logic_vector := "1111";
    constant c_LAD_INPUT_PATTERN: std_Logic_vector := "ZZZZ";
    
    constant c_LAD_START_PATTERN: std_Logic_vector := "0000";
    constant c_CYC_MEM_PREFIX: std_Logic_vector := "01";
    
    constant c_CYC_DIRECTION_READ: std_logic := '0';
    constant c_CYC_DIRECTION_WRITE: std_logic := '1';

    constant c_LAD_ADDR_PATTERN1: std_Logic_vector := "1111";
    
    constant c_LAD_ST49LF020A_ADDR_PATTERN1: std_Logic_vector := "1100"; -- 1st (highest) addr nibble. Fixed addr bit & MSB Chip ID
    constant c_LAD_ST49LF020A_ADDR_PATTERN2: std_Logic_vector := "00"; -- 2nd addr nibble. 2 LSB chip ID

    constant c_FSM_COUNT_RESET: integer := 0;
  
    constant c_FSM_ADDR_SEQ_NIBBLE0: integer := 0;
    constant c_FSM_ADDR_SEQ_NIBBLE1: integer := 1;
    constant c_FSM_ADDR_SEQ_NIBBLE2: integer := 2;
    constant c_FSM_ADDR_SEQ_NIBBLE3: integer := 3;
    constant c_FSM_ADDR_SEQ_NIBBLE6: integer := 6;
    constant c_FSM_ADDR_SEQ_NIBBLE7: integer := 7;
    
    constant c_FSM_DATA_SEQ_TAR2_READ: integer := 1;
    constant c_FSM_DATA_SEQ_TAR1_WRITE: integer := 3;
    
    constant c_FSM_ADDR_SEQ_MAX_COUNT: integer := c_FSM_ADDR_SEQ_NIBBLE7;
    constant c_FSM_DATA_SEQ_MAX_COUNT: integer := c_FSM_ADDR_SEQ_NIBBLE6;
    
    constant c_WRITE_DISABLED: std_logic := '0';

--***+ types +***
    -- Regroup the necessary 17 cycle for a single byte of data transfer (both in R/W).
    type LPC_FSM is 
    (
        LPC_FSM_WAIT_START, -- 0000 read, occurs with LFRAME output asserted. Active while idle and on START frame (1/17 cycle)
        LPC_FSM_GET_CYC,    -- next nibble is CYCTYPE. Active 1/17 cycle.
        LPC_FSM_GET_ADDR,   -- 8 nibbles of address, most significant nibble first. Active 8/17 cycles for mem CYC ops or 4 for IO CYC ops
        LPC_FSM_DATA        -- TAR,SYNC and DATA transfer sequences. Active 7/17 cycles.
    );                      -- For a total of 17 cycles :)



--***+ signals +***
    signal s_lpc_fsm_state  : LPC_FSM;                      -- 2 bit state descriptor, unless you add entries to "LPC_FSM".
    signal s_fsm_counter    : integer range c_FSM_COUNT_RESET to c_FSM_ADDR_SEQ_MAX_COUNT; -- Used for addresses resolution and LPC_FSM_DATA state counter.
    signal s_lad_dir        : std_logic;                    -- 0 for Flash to Xbox(LPC read)
    signal s_device_disable : std_logic;
    signal s_is_init        : boolean := false;             -- Explicitely defined for a reason.
    signal s_write_disabled : boolean;


begin

--***+ direct signals +***

    -- Put pinout_pad_l1 in high impedance if s_device_disable is set. Xbox console can read the onboard BIOS. 
    -- If s_device_disable is not set, pinout_pad_l1 is forced to '1' only when LFRAME signal is asserted on Xbox motherboard.
    -- Eliminates the problem with most modchips not releasing LFRAME.
    pinout_pad_l1<='Z' when (s_device_disable = c_DEVICE_DISABLED or pinout4_xbox_lad = c_LAD_IDLE_PATTERN or s_lpc_fsm_state /= LPC_FSM_WAIT_START) else '1';  

    -- Puts D0 on motherboard in High-Z when s_device_disable is set. Xbox console can read the onboard TSOP. 
    pinout_pad_d0 <='Z' when s_device_disable = c_DEVICE_DISABLED else '0'; 
    -- When s_device_disable is not set, pinout_pad_d0 is forced to ground and Xbox reads from LPC bus instead.
    pinout_pad_x <='Z' when s_device_disable = c_DEVICE_DISABLED else '0';  

    -- Recreate LFRAME for Flash chip. Async.
    pout_flash_lframe <= '0' when s_device_disable = c_DEVICE_ENABLED and pinout4_xbox_lad = c_LAD_START_PATTERN and s_lpc_fsm_state = LPC_FSM_WAIT_START else '1';

--***+ processes +***

    -- Process that checks if Power Button was pressed for a long period.
    process_init : process(pin_xbox_n_lrst, s_is_init)
    begin
        if pin_xbox_n_lrst'event and pin_xbox_n_lrst = '1' then -- Reset goes high a short while after boot sequence has started. That's how you deactivate the modchip, by a long press on power button.
            s_device_disable <= NOT pin_pad_bt; -- Power button state transferred to internal signal
        end if;
        if s_is_init /= true then
            s_device_disable <= c_DEVICE_ENABLED;
        end if;
    end process process_init;

    -- Process that cycle through all the steps of LPC transaction. 
    process_lpc_decode : process(pin_xbox_lclk) -- 33MHz
    begin
        if rising_edge(pin_xbox_lclk) then
            if pin_xbox_n_lrst = '0' or s_is_init /= true then  -- Still too early in boot sequence. We must wait for RST to go high.
                s_lpc_fsm_state <= LPC_FSM_WAIT_START;
                s_is_init <= true;
            else -- There we go!
                if s_fsm_counter < c_FSM_ADDR_SEQ_MAX_COUNT then
                    s_fsm_counter <= s_fsm_counter + 1;
                else
                    s_fsm_counter <= c_FSM_COUNT_RESET;
                end if;
                case s_lpc_fsm_state is
                    when LPC_FSM_WAIT_START =>  -- 0000 read, occurs with LFRAME output asserted
                        if pinout4_xbox_lad = c_LAD_START_PATTERN and s_device_disable = c_DEVICE_ENABLED then -- its a start
                            s_lpc_fsm_state <= LPC_FSM_GET_CYC;
                        end if;                         
                    when LPC_FSM_GET_CYC => -- next nibble is CYCTYPE, only interested in 010x (mem rd) and 011x (mem write), size is always 1 byte for memory
                        if pinout4_xbox_lad(3 downto 2) = c_CYC_MEM_PREFIX then -- memory read or write
                            s_lad_dir <= pinout4_xbox_lad(1);   --'0' is for flash read.
                            s_lpc_fsm_state <= LPC_FSM_GET_ADDR;
                            s_fsm_counter <= c_FSM_COUNT_RESET;
                        else
                            s_lpc_fsm_state <= LPC_FSM_WAIT_START; -- sit out any unsupported cycle until the next start. This section could be expanded to allow other LPC message to go through
                            -- Maybe follow along any unsupported lpc transactions for more robustness?
                        end if;
                            
                    when LPC_FSM_GET_ADDR => -- 8 nibbles of address, most significant nibble first
                        if s_fsm_counter = c_FSM_ADDR_SEQ_NIBBLE0 or s_fsm_counter = c_FSM_ADDR_SEQ_NIBBLE1 then    --2 first nibbles will always be 0xFF. If not, there's an error.
                            if pinout4_xbox_lad /= c_LAD_ADDR_PATTERN1 then
                                s_lpc_fsm_state <= LPC_FSM_WAIT_START; -- sit out any unsupported cycle until the next start.
                                -- Again, this section could be expand in the event a program would want to access something else than BIOS flash.
                            end if; 
                        elsif s_fsm_counter = c_FSM_ADDR_SEQ_MAX_COUNT then -- got the 8 addresses nibbles.
                            s_fsm_counter <= c_FSM_COUNT_RESET;
                            s_lpc_fsm_state <= LPC_FSM_DATA;    -- Next state once all 32 bits of addressing have been transferred (from the Xbox).
                        end if;
                    when LPC_FSM_DATA =>
                        if s_fsm_counter = c_FSM_DATA_SEQ_MAX_COUNT then    -- Could be trimmed down to "110" but the Xbox takes quite a break between each LPC operations.
                            s_lpc_fsm_state <= LPC_FSM_WAIT_START;  -- Will always signals the end of a R/W cycle.
                        end if;
                    when others =>
                        null;
                end case;                   
            end if; -- pin_xbox_n_lrst
        end if; -- clock
    end process process_lpc_decode;
    
    -- Process that detect when LPC mem write ops should not be relayed to the flash cip.
    -- Necessary because SST49LF020 has an addressing bug. Will accept any address range.
    -- We need to supply dummy/invalid CYC code so it will abandon LPC cycle
    process_write_disable : process(s_lpc_fsm_state, pinout4_xbox_lad, pin_pad_h0)
    begin
        if s_lpc_fsm_state = LPC_FSM_GET_CYC then
            if pinout4_xbox_lad(3 downto 1) = c_CYC_MEM_PREFIX & c_CYC_DIRECTION_WRITE and pin_pad_h0 = c_WRITE_DISABLED then
                s_write_disabled <= true;
            else
                s_write_disabled <= false;
            end if;
        end if;
    end process process_write_disable;

    -- Process that control both LAD ports s_lad_dir
    -- Logic is determined by "s_lpc_fsm_state" and "s_fsm_counter" within a specific "s_lpc_fsm_state" value.
    process_flash_interface: process(s_lpc_fsm_state, pinout4_xbox_lad, pinout4_flash_lad, s_lad_dir, s_fsm_counter, pin_xbox_lclk)
    begin
        if falling_edge(pin_xbox_lclk) then  
            if s_write_disabled = true then
                pinout4_flash_lad <= c_LAD_IDLE_PATTERN; -- Most important thing is to serve CYC of "11xx" to flash device. Unsupported CYC op.
                pinout4_xbox_lad <= c_LAD_INPUT_PATTERN;
            elsif s_lpc_fsm_state = LPC_FSM_DATA and ((s_lad_dir = c_CYC_DIRECTION_READ and s_fsm_counter >= c_FSM_DATA_SEQ_TAR2_READ) or (s_lad_dir = c_CYC_DIRECTION_WRITE and s_fsm_counter >= c_FSM_DATA_SEQ_TAR1_WRITE)) and s_fsm_counter <= c_FSM_DATA_SEQ_MAX_COUNT then -- Sequences that reverse data flow. From LPC Flash to Xbox
                pinout4_flash_lad <= c_LAD_INPUT_PATTERN;       -- Flash chips is leading the show.
                pinout4_xbox_lad <= pinout4_flash_lad;  -- pinout4_flash_lad will be "0000" on s_lpc_fsm_state = LPC_SYNC. LPC_SYNC, LPC_DATA1, LPC_DATA2 and LPC_TARB1 are now happening at the same time on both LAD ports(because of TLPC_SYNC_WAIT state).
                --The rest of the time, everybody is in high-Z with internal pull ups so the necessary 0xF nibbles are all there.
            else    -- If not one of the condition above, it means the data flow goes from the Xbox to the LPC flash. Happens on LFRAME start, CYC decode, 8 address nibbles, TARA1, TARB2 and of course when idle.
                pinout4_xbox_lad <= c_LAD_INPUT_PATTERN;        -- Also when s_lad_dir = '1' for DATA1 and DATA2.
                if s_lpc_fsm_state = LPC_FSM_GET_ADDR and s_fsm_counter = c_FSM_ADDR_SEQ_NIBBLE2 then   -- this step is happening on pinout4_flash_lad 1 cycle after it happened on pinout4_xbox_lad.
                    pinout4_flash_lad <= c_LAD_ST49LF020A_ADDR_PATTERN1;
                elsif s_lpc_fsm_state = LPC_FSM_GET_ADDR and s_fsm_counter = c_FSM_ADDR_SEQ_NIBBLE3 then 
                    pinout4_flash_lad <= c_LAD_ST49LF020A_ADDR_PATTERN2 & pinout4_xbox_lad(1 downto 0);
                else
                    pinout4_flash_lad <= pinout4_xbox_lad;  -- Transfer of buffer into the flash LPC port.
                end if; 
            end if;
        end if;
    end process process_flash_interface;

end arch_lpcmod;
