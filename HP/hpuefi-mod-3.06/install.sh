#!/bin/bash
# Automated installation script for hpuefi kernel module

install_modules() {
echo "=========================================="
echo "HP UEFI Kernel Module Installation"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root (use sudo)"
    return 1
fi

# Step 1: Remove old module if loaded
echo "Step 1: Removing old hpuefi module (if loaded)..."
if lsmod | grep -q hpuefi; then
    rmmod hpuefi 2>/dev/null || true
    echo "  Old hpuefi module removed"
else
    echo "  No old module found"
fi

# Step 2: Build the module
echo ""
echo "Step 2: Building kernel module..."
make clean 2>&1
make 2>&1

if [ ! -f hpuefi.ko ]; then
    echo "ERROR: Build failed, hpuefi.ko not found"
    return 1
fi
echo "  Build successful"

# Step 3: Load the module
echo ""
echo "Step 3: Loading hpuefi module..."
insmod hpuefi.ko
if [ $? -eq 0 ]; then
    echo "  Module loaded successfully"
else
    echo "ERROR: Failed to load module"
    return 1
fi

# Step 4: Create device node
echo ""
echo "Step 4: Creating device node..."
chmod +x mkdevhpuefi
./mkdevhpuefi
if [ $? -eq 0 ]; then
    echo "  Device node created successfully"
else
    echo "ERROR: Failed to create device node"
    return 1
fi

# Step 5: Verify installation
echo ""
echo "Step 5: Verifying installation..."
if lsmod | grep -q "^hpuefi "; then
    echo "  hpuefi module is loaded: ✓"
else
    echo "  hpuefi module is NOT loaded: ✗"
    return 1
fi

if [ -c /dev/hpuefi ]; then
    echo "  Device node exists: ✓"
    ls -l /dev/hpuefi
else
    echo "  Device node NOT found: ✗"
    return 1
fi

# Step 6: Install module to system directory
echo ""
echo "Step 6: Installing module to system directory..."
KVER=$(uname -r)
MODULE_DIR="/lib/modules/${KVER}/extra"
mkdir -p ${MODULE_DIR}
cp hpuefi.ko ${MODULE_DIR}/
depmod -a
echo "  Module installed to ${MODULE_DIR}"

echo ""
echo "=========================================="
echo "Installation completed successfully!"
echo "=========================================="
echo ""
echo "The hpuefi module is now loaded and ready to use."
echo "Device: /dev/hpuefi"
echo ""
echo "Note: This installation is temporary and will not"
echo "persist after reboot. To uninstall, run:"
echo "  sudo ./uninstall.sh"

return 0
}

# Call the function and capture return value
install_modules
exit_code=$?

# Don't use exit if sourced, just return the code
if [ -n "$BASH_SOURCE" ] && [ "$BASH_SOURCE" != "$0" ]; then
    return $exit_code
fi

exit $exit_code
