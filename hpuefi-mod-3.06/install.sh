#!/bin/bash
# Automated installation script for hpuefi kernel module

echo "=========================================="
echo "HP UEFI Kernel Module Installation"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root (use sudo)"
    exit 1
fi

# Step 1: Remove old module if loaded
echo "Step 1: Removing old hpuefi module (if loaded)..."
if lsmod | grep -q hpuefi; then
    rmmod hpuefi 2>/dev/null || true
    echo "  Old module removed"
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
    exit 1
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
    exit 1
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
    exit 1
fi

# Step 5: Verify installation
echo ""
echo "Step 5: Verifying installation..."
if lsmod | grep -q hpuefi; then
    echo "  Module is loaded: ✓"
else
    echo "  Module is NOT loaded: ✗"
    exit 1
fi

if [ -c /dev/hpuefi ]; then
    echo "  Device node exists: ✓"
    ls -l /dev/hpuefi
else
    echo "  Device node NOT found: ✗"
    exit 1
fi

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
