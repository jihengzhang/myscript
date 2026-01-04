----------------------
DISCLAIMER OF WARRANTY

The following image: U6x_xxxxxx.iso is experimental and is provided 
as a courtesy, free of charge, "AS-IS" by Hewlett-Packard Company ("HP"). 
HP shall have no obligation to maintain or support this software. 
HP MAKES NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND REGARDING THIS 
SOFTWARE INCLUDING ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE, TITLE OR NON-INFRINGEMENT. HP SHALL NOT BE LIABLE 
FOR ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES, 
WHETHER BASED ON CONTRACT, TORT OR ANY OTHER LEGAL THEORY, IN CONNECTION 
WITH OR ARISING OUT OF THE FURNISHING, PERFORMANCE OR USE OF THIS SOFTWARE.

---------------------------------------------------------------------------

This file contains the directions on how to burn the U6x_xxxxxx.iso image
onto optical media to update HP Workstations with UEFI System BIOS for Windows 
and Linux operating systems.  It is intended for use only on the following
HP Workstations:

  * Z4 G5
  * Z4 Rack G5
  * Z6 G5
  * Z8 G5
  * Z8 Fury G5


1. Download the latest BIOS SoftPaq from hp.com for your product and then run the executable
2. In the directory you will find a folder named "OpticalF10Update".  Inside this folder you 
will find the image file labeled "U6x_xxxxxx.iso".
3. Burn this image to your optical media using software capable of burning .iso disc images.  
Please don't attempt to extract the .iso file as it is in a disc image format. 
*HP suggests using CD-R or DVD+R media.
4. Place the optical media with the burned image into your optical media drive on the system to
be updated.
5. Press Esc after powering on the system.
6. Once at the Startup Menu select select "Update System and Supported Device Firmware".
7. The system will reboot and perform necessary updates.

NOTE: You may need to disable SATA RAID Mode, enable AHCI Mode, on the system to perform the optical update.


--
Copyright (c) 2023 HP Development Company, L.P.
Last updated revision - Mar 10, 2023


