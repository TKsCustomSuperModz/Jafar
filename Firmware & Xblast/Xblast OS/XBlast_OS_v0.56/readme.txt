!!!!!!!!!!WARNING!!!!!!!!!
This software is currently actively in development and is 
labeled as a BETA. Therefore, using this software on your 
Xbox console could permanently harm your hardware. Although 
it has been extensively tested, the developer(s) cannot and 
will not be held responsible for any damage or lost data.
In other words, use this software at your own risk!


1. Introduction
XBlast OS is a cromwell-based software for the Xbox console.
It's primary use is as a modchip OS for the upcoming
XBlast Mod modchip. However, it has also been made available
as a standalone Xbox executable (XBE) and Bios BIN file to 
flash to a modchip device or onboard TSOP.

Both BIOS bin and XBE file are now universally compatible across 
all Xbox motherboard revisions. No need to have a separate 
version for 1.6b.

"XBlast OS.xbe" is to be run from dashboard
"crcwell.bin" is to be flashed on a modchip/TSOP.
"crcwell.bin" is the OS update file for XBlast devices.

2. Bug reports
If you ever encounter a bug, please do tell me about it.
Please post a detailed explanation of the bug either at
AssemblerGames forums, in the Xbox Original sub-forum, 
or at XBMC4Xbox forums, in the Xbox Modding sub-forum.
You can also create "issues" on the Bitbucket project page:
https://bitbucket.org/psyko_chewbacca/lpcmod_os/issues?status=new&status=open

3. Basic operation
XBlast OS has the ability to save settings and eeprom data 
on your modchip's flash or onboard TSOP (SmartXX modchips 
do not support saving). However, it is important 
to know that no actual writing to physical devices
(modchip flash and/or Xbox eeprom) will be made until a
software request for a reboot or a shutdown is made. This
allows you to freely edit settings and eeprom data and only
commit your changes upon exiting XBlast OS software by 
issuing a software reboot/shutdown command or booting
from a flash bank. If you press the power button or unplug 
your console, the settings you changed since last boot will
not be saved. Note that any changes made to the HDDs are 
commit automatically; same goes for flashing a new BIOS.

If no persistent settings are found on your modchip, the front
LED will flash Red/Orange. XBE version will always starts
flashing Red/Orange. If a proper "xblast.cfg" file is placed in
"C:\XBlast\" folder, settings in this file will be loaded a few 
seconds after launching the XBE.

You can manually load from "xblast.cfg" using the appropriate
option in the "Tool" section. Note that you'll need to commit
the changes by either selecting reboot/shutdown option or
booting a BIOS bank.

It is possible to load custom backdrop and icon sets from
your FATX formatted hard drive. For now, it is only possible
to load JPEG image files from a fixed location. You must place
both "icons.jpg" and "backdrop.jpg" in C:\XBlast on your 
Hard Drive for them to be loaded at launch. A sample set
of image files is supplied with this release. If you want to create
your own, please keep the same resolution for both files.

LCD Settings menu will only be shown if a supported
modchip is detected. Sorry, no Aladdin XT 4064...
Tested LCD are all HDD44780 compatible (most common).
Resolution confirmed working are:
20x4
20x2
16x2
8x1

Resolution confirmed not (completely) working:
Anything above 20 characters per line.
Anything over 4 lines.

128MB Ram test will not be shown on 1.6/1.6b Xboxes.

Locking/Unlocking HDD option will not be shown if a 
connected HDD does not support it.

Saving and restoring Xbox EEProm to flash will not be shown in XBE
version, unless a XBlast Mod is detected.

Flashing a Bios from the HDD lists files from C:\BIOS only.

Last resort EEPROM rescue will completly replace the content 
of your EEPROM by a generic image. This will change your
Xbox serial number, MAC address and possibly Game/Video 
region settings.

Restoring EEPROM from network requires you to upload an
"eeprom.bin" file through the web server; just like for netFlash.
Validity of uploaded EEPROM image is verified before accepting
it. Uploaded EEPROM version must match your Xbox motherboard 
revision.

Lock/Unlock HDD via network requires you to upload an
"eeprom.bin" file through the web server; just like for netFlash.
When using this option, keep in mind most HDD will not accept
anymore than 5 unlock attempts per power cycle. Further 
consecutive attempts most of the time always result in a failure 
even if the correct password was supplied.

You can execute XBlast script at XBlast OS' boot. In the XBE,
when no XBlast Lite has been detected, you need to set the
appropriate option in "xblast.cfg" file ("runbootscript" option)
and have a script file called "boot.script" in "C:\XBlast\scripts".
In BIOS bin version, you need to go to the "XBlast scripts" menu
section to first upload a script file located in "C:\XBlast\scripts"
to your modchips's flash then have to enable boot script option.

You can execute XBlast script just before booting a user BIOS 
bank. You need to have a script file called "bank.script" in 
"C:\XBlast\scripts" and enable the appropriate option in
the "XBlast scripts" menu section.

The Mainmenu screen (called IconMenu) contains several key
elements:
-Type of executable (XBE or ROM)
-Version (currently 0.50)
-Detected Modchip (currently, XBlast Mod Lite, Aladdin XBlast, Xecuter 3(CE) and all SmartXX modchips are supported)
-Conventionnal Xbox revision number.
-Detected CPU frequency
-Amount of RAM detected, in Megabytes.
-A set of icons to choose by using left and right arrows on the D-pad and selecting with A.

The settings screen (called TextMenu) works in this manner:
-Navigate entries using Up and Down arrows on the D-Pad
-Enter selection or toggle option by pressing A or Start.
-Go back by pressing B or Back.
-Most settings can be changed using the D-pad's left and right arrows.
-Simple yes/no or True/false options can also be toggled by pressing A
-Settings with numerical values can be changed using the analog triggers(faster)

For more detailed information on usage, please visit the Wiki.
Wiki is currently in active development. Feel free to contribute.
Wiki is located at the following address:
https://bitbucket.org/psyko_chewbacca/lpcmod_os/wiki/Home

3. XBE version content
Please note that options related to XBlast Mod hardware will
not be shown, unless you have a XBlast Mod detected.
Also, persistent settings like front LED color and Fan speed
will not be saved for your next session.

It is not possible to backup or restore EEProm from flash.

LCD will be supported if supported modchip is detected.


4. Bios BIN version content
Please note that saving settings or EEProm backup to flash isn't 
supported on SmartXX modchips.
Restoring EEPRom backup to Xbox isn't possible as well. You
can run it but you cannot save any setting.

Before saving settings to flash, XBlast OS will verify that the 
current active BIOS bank actually contains a XBlast OS image.
This is to avoid the situation where a user would change active
BIOS bank while running XBlast OS and not change it back when
settings are about to be saved. A warning will appear to indicate
the situation and user will have the choice of either retry or
forgo saving settings back to flash.


4. Known bugs/issues/limitations
-HDD formatting takes a long time for big partitions. 160GB takes about
    25 seconds, 960GB takes a little less than 3 minutes.

-Only HD44780/KS0073 LCDs are supported right now. X3 LCD is
    HD44780-compatible.

-Selecting "Display HDD information" after formatting F:/G: partitions 
   crashes the program. Rebooting fixes it.
   
-Launching XBE version from a debug BIOS does not seem to work

-Since v0.50, a significant change in image integrity check has been 
implemented. In order to update to v0.55, you will need to have your
XBlast device already at version 0.50. Earlier versions of XBlast OS
will reject v0.55 update file has invalid image.This will not be the
for subsequent updates until further notice.


5. Remarks
I know, on-screen keyboard is not so pleasant. I put my efforts on
functionality!