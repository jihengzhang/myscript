#!/bin/sh
#
# Manual installation help for HP uefi flash and repset utilities rpm
#

if [ `whoami` != root ]; then
   echo "Must be root to run this script."
   return 1 2>/dev/null || exit 1
fi

# Test dependencies before installation
. ./builds/test-distro.sh

echo "Installing hp-flash UEFI BIOS utilities in /opt/hp/hp-flash..."

srcDir=`pwd`

install -D -m 0744 ${srcDir}/bin/hp-flash /opt/hp/hp-flash/bin/hp-flash
install -D -m 0744 ${srcDir}/hp-flash /opt/hp/hp-flash/hp-flash
install -D -m 0644 ${srcDir}/docs/hp-flash-README /opt/hp/hp-flash/docs/hp-flash-README
install -D -m 0744 ${srcDir}/bin/hp-repsetup /opt/hp/hp-flash/bin/hp-repsetup
install -D -m 0744 ${srcDir}/hp-repsetup /opt/hp/hp-flash/hp-repsetup
install -D -m 0644 ${srcDir}/docs/hp-repsetup-README /opt/hp/hp-flash/docs/hp-repsetup-README

echo "Done."

