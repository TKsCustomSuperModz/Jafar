
# Jafar
![Jafar LOGO](https://github.com/TKsCustomSuperModz/Jafar/blob/main/Images/Jafar%20Logo.png?raw=true)

This is a custom board reimagination of the Aladdin chip for the Original Xbox.
This VHDL was written by Psyko_Chewbacca and released with his AladdinXBlast repository available [here](https://bitbucket.org/psyko_chewbacca/aladdin_xt_cpld)

# Licensing

Jafar is free and open source. Please respect the licenses available in their respective folders.

-   Hardware is shared under the  [CERN OHL version 1.2.](https://ohwr.org/cernohl).
-   Firmware is shared under  [GPLv3](https://www.gnu.org/licenses/quick-guide-gplv3.en.html).

# Instructions

1.  Connect a JTAG programmer to the JTAG pins shown below.
    
2.  Make sure to apply 3.3V power to the Jafar board. This can be done by plugging it into the LPC port on the Xbox, an external power supply, or a JTAG programmer that can supply power.  A modified Lattice USB programmer or FlashCat are two examples of programmers that can supply power.
    
3.  Program the CPLD with the  `SVF` or `JED`  file in this repository . It can be programmed with  [UrJTAG](http://urjtag.org/)  using a  [compatible programming cable](http://urjtag.org/book/_system_requirements.html#_supported_jtag_adapters_cables) for the `SVF` or ispVM for the `JED` files. The general programming sequence in UrJTAG is something like: (Commands written in  **bold**).
    
    **cable usbblaster**  _Type  `help cable`  for other supported cables._  
    **detect**  _To confirm that the cpld is detected._  
    **svf FILENAME.SVF progress**  _To program the CPLD._
        
4.  Remove the JTAG programming points.
    
5.  The flash chip needs to either be programmed ahead of time, or can be hot-swapped with an existing chip to program it.
        
6.  Install onto the LPC header in your Xbox. You can either ground the D0 points or attach D0 to the pad on the Jafar chip to drive it correctly using the onboard FET.
