----------------------
DISCLAIMER OF WARRANTY

The following software: 'hp-flash' and 'hp-repsetup' are experimental
and is provided as a courtesy, free of charge, "AS-IS" by HP Development 
Company, L.P.  HP shall have no obligation to maintain or support this 
software.  HP MAKES NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND REGARDING 
THIS SOFTWARE INCLUDING ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE, TITLE OR NON-INFRINGEMENT. HP SHALL NOT BE LIABLE
FOR ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES,
WHETHER BASED ON CONTRACT, TORT OR ANY OTHER LEGAL THEORY, IN CONNECTION
WITH OR ARISING OUT OF THE FURNISHING, PERFORMANCE OR USE OF THIS SOFTWARE.

---------------------------------------------------------------------------

This archive contains the 'hp-flash' and 'hp-repsetup' toolset for updating
and configuring select HP business notebook, desktop, and workstation systems
with compatible UEFI System BIOS and running Linux operating systems.

  The toolset is compatible with the following HP systems:
     2015 and newer HP Desktop Workstations
     2018 and newer HP business Notebooks and Desktops.

This utility will not work on platforms prior to those listed above.

The utilities support RPM-based and non-RPM-based package management
environments.  The documents directory provides PDF and ASCII text
[unix] formatted installation / usage instructions.

32-bit installations [i686] are not supported by these utilities.

/rpms
    /rpms/*/hpuefi-mod-3.06-1.src.rpm           # Kernel module (all)
    /rpms/rh70/hp-flash-3.25-1.rh70.x86_64.rpm  # RHEL 7.x compatible
                                                #  all 7.0,7.1,7.2,..
    /rpms/rh80/hp-flash-3.25-1.rh80.x86_64.rpm  # RHEL 8.x compatible
                                                #  all 8.0,8.1,8.2,..
    /rpms/rh90/hp-flash-3.25-1.rh90.x86_64.rpm  # RHEL 9.x compatible
                                                #  all 9.0,9.1,9.2,..
    /rpms/sled12/hp-flash-3.25-1.sled12.x86_64.rpm # SLED 12 compatible
    /rpms/sled15/hp-flash-3.25-1.sled15.x86_64.rpm # SLED 15 compatible
/non-rpms
    /non-rpms/hp-flash-3.25_x86_64.tgz          # RH7.x, RH8.x, RH9.x,
                                                # SLE12, SLE15
                                                # U16, U18, U20, U21, 
                                                # U22, U24 compatible
    /non-rpms/hpuefi-mod-3.06.tgz
/docs
    /docs/HP Linux Tools Readme.pdf
    /docs/HP Linux Tools Readme.rtf
    /docs/HP Linux Tools Readme.txt


--
Copyright (c) 2025 HP Development Company, L.P.
Last updated revision - February 25, 2025


