
DISCLAIMER OF WARRANTY
The following software: hp-flash and hp-repsetup are experimental and is provided as a courtesy, free of charge, "AS-IS" by HP Development Company, L.P. HP shall have no obligation to maintain or support this software. HP MAKES NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND REGARDING THIS SOFTWARE INCLUDING ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE OR NON-INFRINGEMENT. HP SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES, WHETHER BASED ON CONTRACT, TORT OR ANY OTHER LEGAL THEORY, IN CONNECTION WITH OR ARISING OUT OF THE FURNISHING, PERFORMANCE OR USE OF THIS SOFTWARE.

HP Linux Tools User's Guide

  This archive contains the 'hp-flash' and 'hp-repsetup' toolset for 	updating and configuring select HP business notebook, desktop, and 	workstation systems with compatible UEFI System BIOS and running 	Linux operating systems.

  The toolset is compatible with the following HP systems:
   	2015 and newer HP Desktop Workstations
   	2018 and newer HP business Notebooks and Desktops.

NOTE: This utility will not work on platforms prior to those listed above.

'hp-flash', 'hp-resetup' and supporting kernel module, 'hpuefi-mod' are distributed without warrantee or guaranteed compatibility with future systems. This version of Linux utilities (herein defined to mean both binary utilities and matching source-level kernel module) was tested on Red Hat Enterprise Linux 7, 8, 9 (RHEL 7, RHEL 8, RHEL 9), SuSE Linux Enterprise Desktop 12 and Desktop 15 (SLED12, SLED15), and Canonical Ubuntu 16.04 / 18.04 / 20.04 / 21.04 / 22.04 / 24.04 distributions running 64-bit kernels.


What's in the package?

'hp-flash' has two main components, the 'hpuefi-mod' kernel module, and the 'hp-flash' application.

* The 'hpuefi-mod' kernel module is distributed as a source RPM called 
o hpuefi-mod.<version>.src.rpm

* The 'hp-flash' application set ('hp-flash' and 'hp-repsetup') is distributed as an RPM called
o hp-flash-<version>.<architecture>.rpm

Non RPM-based distributions can be supported with:
* hpuefi-mod-x.x.x.tgz			# manual build/installation
* hp-flash-<version><architecture>.tgz # manual installation

Installation

The kernel module must be installed before the application.  Be sure that you have the 'development' option for RHEL (or 'C/C++ development' option for SLED) installed on your system before you attempt to install the 'hpuefi-mod' module and app.  One of these RPMs that HP is providing requires you to build a binary component from source.  To do this will require the 'rpmbuild' application.  If 'rpmbuild' is not installed on your system, you will need to load it from the RHEL installation media.  You may find while installing the 'rpm-build' RPM that there are other packages which are missing from your system and need to be installed before you can proceed.  Take note of the missing packages and install each one directly from the RHEL media.  Once you have these dependencies taken care of, complete installation of the 'rpm-build' .rpm and proceed with the installation instructions below.

Debian-based installations such as Ubuntu distros will require use of the 'build-essential' development environment to properly compile and install the hpuefi-mod package (provided in the non-rpms directory). This can be installed with:

sudo apt install build-essential 

NOTE: The hp-repsetup utility depends on runtime OpenSSL shared libraries. Users with minimal or alternative distributions will need to ensure availability of OpenSSL libraries to use the hp-repsetup utility.

NOTE: 'root' administration privileges are required for build, installation, and execution of these utilities.  In particular, the build-from-source steps ('rpmbuild') may occur in differing locations according to prevailing system defaults, user definitions ( $HOME/.rpmmacros ), or other environmental overrides.  On some distributions, the following command can help determine the location of build source:

       rpmbuild -showrc | grep _topdir

The value for %{_topdir} reported by the command above may include any of the following paths for your distribution and revision:

* /usr/src/redhat
* $HOME/rpmbuild
* /usr/src/packages

The command examples below use the '$HOME/rpmbuild' version for demonstration.

NOTE: The utilities as provided operate only with Secure Boot environments DISABLED. This means that system BIOS settings must have Secure Boot settings disabled to build and apply the unsigned kernel module necessary for hp-flash and hp-repsetup operations. User environments requiring Secure Boot support for kernel modules should apply their preferred methods for signing the "hpuefi.ko" module before enabling Secure Boot in system BIOS. Signing recommendations can be found in "The Linux kernel user's and administrator's guide" (docs.kernel.org) or support documentation from preferred enterprise Linux distributors that is compatible with the Linux kernel version in use.

NOTE: hpuefi-mod source code kernel module attempts to accommodate a kernel data structure change around 6.3.0 and later. It involves flag setting and later kernels employ an access mechanism instead of direct setting of the flag. Because some kernels may have patches applied that update these access mechanisms without changing their version numbers, conditionally compiled code in the kernel modules earlier than 3.06 broke due to compile-time incompatibilities. A helper script attempts to dynamically detect the currently active access mechanisms and provide a modified kernel module source that is compatible with the existing kernel environment. The kernel module code has detailed comments for self-supportability within user custom environments. (See code "VM_LOCKED" for details.)


RPM-based Distribution Installation

To install the kernel module:
* rpm -i hpuefi-mod-<version>.src.rpm
* rpmbuild -bb $HOME/rpmbuild/SPECS/hpuefi-mod.spec
* rpm -i $HOME/rpmbuild/RPMS/<architecture>/hpuefi-mod-<version>.rpm

To install the application:
* rpm -i hp-flash-<version>.<architecture>.rpm

The utility applications and current help documentation files are now installed on the system in the following parent directory:

* /opt/hp/hp-flash

Non RPM-based Distribution Installation

To install the kernel module:
* tar xzf hpuefi-mod-x.x.x.tgz
* cd hpuefi-mod-x.x.x/
* make
* sudo make install

To install the utility applications:
* tar xzf hp-flash-<version><architecture>.tgz
* cd hp-flash-<version><architecture>
* sudo ./install.sh

The utility applications and current help documentation files are now installed on the system in the following parent directory:

* /opt/hp/hp-flash


BIOS Flashing

Attention: The flashed BIOS image is not checked for validity. Only flash the system BIOS with BIN file from the HP support website.  BIOS files that are not supported by the 'hp-flash' tool and the target platform may report an error.  See further documentation below.

'hp-flash' can be used to update a system's BIOS. 

To update (flash) the BIOS, obtain a current BIN file for the target system from the HP support website. Follow the posted instructions for extracting this file from the posted SoftPAQ archive, if necessary. A call made to the application (as a system administrator) to update the bios with the supplied BIN file will update the system immediately upon reboot: 

* /opt/hp/hp-flash/hp-flash [flags] <romfile.bin>

NOTE: DO NOT restart the system WHILE flashing is in progress.  The system will become unresponsive for a few seconds. The changes will take effect after a reboot.

* Usage: hp-flash [-q -y -h -?] [-p admin_password] [-i] filename
    		-q  (Quiet Mode)     - Minimize text output
    		-y  (Yes Mode) - Answer Yes to everything (non-interactive)
           	-h, -?               - Show this help message
           	-p admin_password    - Input BIOS Admin Password
           	-i filename | delete - Flash (or delete) a custom startup
 						logo image
           	filename             - ROM binary or image file to flash


Other Useful Options

   Password
If a BIOS password is set on the system, it will need to be supplied on the command line using the -p option for changes to be made. 

       For example: 
           /opt/hp/hp-flash/hp-flash -p <admin_password> <romfile.bin>

   Automate
Use the -y (Yes Mode) option to turn off user prompts for full automation / non-interactive execution of the process.

       For example:
           /opt/hp/hp-flash/hp-flash -y <romfile.bin> 

   Quiet
       Use the -q (Quiet Mode) option to minimize output text.
       
       For example:
           /opt/hp/hp-flash/hp-flash -q <setup passwd> <romfile.bin>

   Help
Use the -h or -? flags to display command line help messages for current usage.

   Custom Image Logo
Some versions of this utility will support alternate boot splash images for platform customization.  See the file /opt/hp/hp-flash/hp-flash-README for details in your specific version.
Replicated Setup

'hp-repsetup' replicated setup (repset) supports limited functionality to clone UEFI BIOS Settings in an enterprise environment of HP systems of the same type running Linux. The repset feature mimics the BIOS F10 setup menu. BIOS settings are saved to a file, and can be restored from the file. 'hp-repsetup' implements repset from the command line. Here is a procedure for using this feature to clone BIOS settings from one unit to the next:

1. Enter the BIOS setup menu (hit <F10> at boot) and customize settings.
2. Reboot the system, and use 'hp-repsetup' to grab the repset file ("get" mode via the -g flag):
a. /opt/hp/hp-flash/hp-repsetup -g <saverep.txt>
b. This will save all BIOS settings to the file.
3. Transfer the repset file to a target system of the same type. Apply the repset file via the "set" mode using the -s flag: 
a. /op/hp/hp-lxbios/hp-repsetup -s <saverep.txt>
b. This will apply all changes. Changes will take effect after a reboot

NOTE: Only fields specified in a saved repset file will update the same settings when read and installed by the 'hp-repsetup' tool.  Editing the captured file with UCS-2 compatible editors (UTF-16 Unicode with fixed-width 16-bit characters) is allowed provided that formatting is not altered (whitespace is significant).  An ASCII-compatible dump is also supported by this tool (but the results are only usable by this tool and no other replicated setup utilities).

   	Usage: hp-repsetup	[-g | -s] [-q -a -h -?] 
       [-p admin_password | -n admin_passwd] 
[-cspwdfile filename | -nspwdfile filename] [filename]

       -g  (Get Mode)  - Get BIOS settings [requires get OR
        set command]
       -s  (Set Mode)  - Set BIOS settings [requires get OR set
        command]
           	-q  (Quiet Mode)- Minimize text output (default: Verbose
        Mode)
       -a  (ASCII Mode)- Create file in ASCII format (default:
        Unicode UCS-2)*
       NOTE: ASCII file cannot be imported with other tools
           	-h, -?              - Show this help message
           	-p admin_password   - Input current BIOS Setup Password
           	-n admin_password   - Input new BIOS Setup Password
           	-cspwdfile filename - Input current BIOS Setup Password from
       filename**
           -nspwdfile filename - Input new BIOS Setup Password from							filename**
                	NOTE: Special file currently only creatable from
       Windows-based utilities
           	filename            - Optional (default: HpSetup.txt)

Other Useful Options

   Password
If a BIOS password is set on the system, it will need to be supplied on the command line (or through a file) using the -p option for changes to be made.

For example: 
/opt/hp/hp-flash/hp-repsetup -p <admin_password> <saverep.txt> 

If setting a new BIOS password, then that activity can be accommodated by providing the current password (if set) and the new password.

For example: 
           /opt/hp/hp-flash/hp-repsetup [-p <cur_passwd>] -n <new_passwd>

BIOS setup passwords can be encoded into a special file to improve security (instead of entering them in clear text).  Currently, the only utilities available to do so are not available on Linux. See the appendix at the end of this document for examples of file generation. The command requirements differ from the command-line version only in the type of file (or files) required as arguments.

For example:
/opt/hp/hp-flash/hp-repsetup [-cspwdfile curpassfile] -nspwdfile newpassfile

   Quiet
           Use the -q (Quiet Mode) option to minimize output text.

       For example:
           /opt/hp/hp-flash/hp-repsetup -q <setup passwd> <saverep.txt>

   Help
Use the -h or -? flags to display command line help messages for current usage.

   ASCII
Use of the -a (ASCII Mode) option allows this tool to dump or read an ASCII compatible repset file instead of the BIOS standard default format which is in UCS-2 format (UTF-16 Unicode with fixed-width 16-bit characters).

NOTE: Data dumped in this format is not compatible with any other replicated setup tools and is unique to this utility.  Use of this output with other tools or F10 is undefined and unsupported.


Attention: Compatible 'hp-repsetup' password files currently can only be generated by utilities available with HP BIOS packages for Windows systems.  The following documentation shows the generation of these special password files with the provided utilities.

The utilities HpqPswd and HpqPswd64 reside in System BIOS packages for Windows.

   	For example:
a. download HP Z440/Z640/Z840 Workstation System BIOS (1.53 Rev.A - 7 Apr 2015) onto your Windows client and unpack it.

b. With Windows Explorer, navigate to the appropriate folder after unpacking a system BIOS package.
c. For example, see the HpqPswd sub-folder in the image below:
   c:\swsetup\SP71139\HPQPASSWD

d. Once there, you can execute either appropriate tool for your version of Windows (32-bit or 64-bit):

e. The GUI for HpqPswd[64] executable allows the input of the desired password to encode and a set of methods to name and locate the appropriate output file used for your Linux installation.  Use these files with -cspwfile and -nspwfile command flags to 'hp-resetup'.


Copyright (c) 2014 - 2025 HP Development Company, L.P.
Last updated revision - Feb 25, 2025
