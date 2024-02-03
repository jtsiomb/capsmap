capsmap - DOS TSR for remapping caps lock
-----------------------------------------

Author: John Tsiombikas <nuclear@mutantstargoat.com>  
This program is placed in the public domain. Do whatever you like with it.

Capsmap is a DOS Terminate and Stay Resident program, for remapping caps lock
to any other key. It does this by taking control of the keyboard interrupt, and
either modifying the BIOS keyboard flag bytes (for modifier keys), or appending
scancodes to the BIOS keyboard buffer, when it detects a caps lock
press/release. This remapping trick will work for most DOS programs which use
either BIOS or DOS calls to get keyboard input. It will not work however for any
programs which access the keyboard directly, like most games.

Two pre-built versions of the caps mapper are provided in the release archive.
 - `capsmap.com` maps caps lock to the left control key.
 - `capsesc.com` maps caps lock to the escape key.

If you wish to map caps lock to something else, you need to rebuild the program
after changing a couple of definitions in the top of `capsmap.asm`, following
the instructions in the comments. To figure out which scancode number to set in
the code, use the accompanying `testkeys.com` program.
