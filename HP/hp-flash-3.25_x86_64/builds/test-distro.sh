#!/bin/sh
#
# test-distro.sh - attempt to match libcrypto (OpenSSL) dependencies
#                  with runtime environment (libcrypto differs across
#                  user-defined environments) - may fail to find 
#                  a valid runtime environment with provided build cache
#

# hp-repsetup-libcrypto-check () { -----------------------------------

  srcDir=`pwd`; 

  # Setup for installation testing -----------------------------------

  MODPROBESUPPORT=`strings /sbin/modprobe | grep -c allow_unsupported`
  if [ ${MODPROBESUPPORT} -gt 0 ]; then
    MODPROBEARGS="--allow-unsupported"
  else
    MODPROBEARGS=" "
  fi

  /sbin/modprobe ${MODPROBEARGS} hpuefi
  RET=$?
  if [ ${RET} -ne 0 ]
  then
    echo "ERROR: Could not load module hpuefi"
    echo "       Make sure that the package hpuefi-mod is installed"
    exit ${RET}
  fi

  # Create proper HPUEFI device file required for this kernel
  if [ ! -c /dev/hpuefi ]; then
    if [ -x /lib/modules/`uname -r`/kernel/drivers/hpuefi/mkdevhpuefi ]; then
      /lib/modules/`uname -r`/kernel/drivers/hpuefi/mkdevhpuefi
    else
      echo "ERROR: Unable to create /dev/hpuefi"
      echo "       Make sure that the package hpuefi-mod is installed"
      exit -1
    fi 
  fi

  # HP Supported -----------------------------------------------------
  #   Red Hat 7.0
  #   Red Hat 8.0
  #   Red Hat 9.0
  #   SuSE SLED 12
  #   SuSE SLED 15
  #   Ubuntu 16.04
  #   Ubuntu 18.04
  #   Ubuntu 20.04
  #   Ubuntu 22.04
  #   Ubuntu 24.04

  if [ -d /boot/efi/EFI/redhat -o -f /etc/redhat-release ]; then
    TARGETS="rh70 rh80 rh90"
  elif [ -d /boot/efi/EFI/sled -o -d /boot/efi/EFI/sles ]; then
    TARGETS="sled12 sled15"
  elif [ -d /boot/efi/EFI/ubuntu ]; then
    TARGETS="u1604 u1804 u2004 u2104 u2204 u2304 u2310 u2404 u2410"

  # HP Unsupported ---------------------------------------------------
  #   Centos 7.0     (assumes Red Hat 7.0)
  #   Centos 8.0     (assumes Red Hat 8.0)
  elif [ -d /boot/efi/EFI/centos -o -f /etc/centos-release ]; then
    TARGETS="rh70 rh80 rh90"

  # No Targets found -- attempting all possible candidates -----------
  #   Attempt to use all cached builds for possible candidate version
  #   of libcrypto 

  else
   TARGETS="rh70 rh80 rh90 u1604 u1804 u2004 u2104 u2204 u2304 u2310 u2404 u2410 sled12 sled15"
  fi

  # Installation test and verify -------------------------------------

  INSTALLTARGET="None";

  for distro in ${TARGETS}; do
    CHECKFILE=${srcDir}/builds/hp-repsetup.$distro
    CHKCOUNT=`ldd ${CHECKFILE} | grep crypto | grep -c found`

    if [ ${CHKCOUNT} -eq 0 ]; then
      ${CHECKFILE} -q > /dev/null 2>&1
      RET=$?

      # Test execution succeeded
      if [ ${RET} -eq 0 ]; then
        INSTALLTARGET=${distro}
        break;
      fi
    fi
  done

  if [ ${INSTALLTARGET} = "None" ]; then
    echo "** Install FAILED ** : no compatible libcrypto (OpenSSL) libraries found."
    exit 1
  else 
    #
    # Transfer compatible targets to installation directory (OpenSSL match)
    #
    cp -p ${srcDir}/builds/hp-flash.${INSTALLTARGET} ${srcDir}/bin/hp-flash
    cp -p ${srcDir}/builds/hp-repsetup.${INSTALLTARGET} ${srcDir}/bin/hp-repsetup
  fi

# } ------------------------------------------------------------------
   
# hp-repsetup-libcrypto-check ;			# If BASH, call proc (future)


