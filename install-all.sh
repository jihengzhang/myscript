#!/bin/bash
#
# Master installation script for HP UEFI tools
#

echo "=========================================="
echo "HP UEFI Tools - Master Installation"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root (use sudo)"
    return 1 2>/dev/null || exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Step 1: Install hpuefi kernel module
echo "Step 1: Installing hpuefi kernel module..."
echo "----------------------------------------"
cd "$SCRIPT_DIR/hpuefi-mod-3.06" || exit 1
bash install.sh
if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Failed to install hpuefi module"
    return 1 2>/dev/null || exit 1
fi

# Step 2: Install hp-flash utilities
echo ""
echo "Step 2: Installing hp-flash utilities..."
echo "----------------------------------------"
cd "$SCRIPT_DIR/hp-flash-3.25_x86_64" || exit 1
bash install.sh
if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Failed to install hp-flash utilities"
    return 1 2>/dev/null || exit 1
fi

cd "$SCRIPT_DIR"

# Step 3: Create symbolic links for easy access
echo ""
echo "Step 3: Creating symbolic links..."
echo "----------------------------------------"
ln -sf /opt/hp/hp-flash/bin/hp-flash /usr/local/bin/hp-flash
ln -sf /opt/hp/hp-flash/bin/hp-repsetup /usr/local/bin/hp-repsetup
echo "  Symbolic links created in /usr/local/bin/"

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Installed components:"
echo "  - hpuefi kernel module: /dev/hpuefi"
echo "  - hp-flash utilities: /opt/hp/hp-flash/"
echo "  - Commands available: hp-flash, hp-repsetup"
echo ""
echo "You can now use hp-flash and hp-repsetup commands."
echo ""
