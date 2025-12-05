#!/bin/sh
#
# This utility script helps work around changes to kernel vm_flags data
# structure that changed at version 6.3.0.  Not all patched kernels 
# reflect the correct kernel version number to match this access change. We
# must correct source code to match what is actively in use by kernel
# (possibly patched) and not based upon version numbering (which was
# an expected compile-time check)
#
# ---
#
#  Kernel driver for Linux UEFI BIOS utilities
#  (c) Copyright 2018 HP Development Company, L.P.
#
#  This program is free software; you can redistribute it and/or modify it
#  under the terms of version 2 of the GNU General Public License as published
#  by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License along with
#  this program; if not, write to:
#  
#    Free Software Foundation, Inc.
#    51 Franklin Street, Fifth Floor
#    Boston, MA 02110-1301, USA.
#
#  The full GNU General Public License is included in this distribution in
#  the file called "COPYING".
#

# Several kernel header path options to check - which one is active?
#   /lib/modules/$KVERS/build
#   /usr/src/linux
#   /usr/src/linux-headers-$KVERS

KVERS=`uname -r`
KHPATHS="/lib/modules/$KVERS/build /usr/src/linux /usr/src/linux-headers-$KVERS"
KMMH="build kernel headers not found"

for thispath in $KHPATHS ; do
    if [ -f $thispath/include/linux/mm.h ]; then
	KMMH=$thispath/include/linux/mm.h ;
	break ;
    fi
done

# No build environment found for this kernel
if [ ! -f $KMMH ]; then
    echo "Fatal error - $KVERS build kernel headers not found"
    exit -1
fi

#
# Look for new private flag access interface in mm.h (kernel 6.3.0 or later)
#
KVER630=`grep -c vm_flags_set $KMMH`

#
# Did we find the correct interface /lib/modules/KVER/build/include/linux/mm.h
#
if [ $KVER630 -eq 0 ]; then
    # Pre 6.3.0 kernel flag-set
    sed -e 's/HP_KVER_VM_FLAGS_LOCKED/vma->vm_flags |= VM_LOCKED/g' hpuefi.c-template > hpuefi.c
else
    # Post 6.3.0 kernel flag-set
    sed -e 's/HP_KVER_VM_FLAGS_LOCKED/vm_flags_set(vma, VM_LOCKED)/g' hpuefi.c-template > hpuefi.c
fi

exit 0

