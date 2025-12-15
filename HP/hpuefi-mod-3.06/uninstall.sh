#!/bin/bash
# Uninstallation script for hpuefi kernel module

echo "=========================================="
echo "HP UEFI Kernel Module Uninstallation"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root (use sudo)"
    exit 1
fi

# Remove device node
echo "Removing device node..."
if [ -c /dev/hpuefi ]; then
    rm -f /dev/hpuefi
    echo "  Device /dev/hpuefi removed"
else
    echo "  Device /dev/hpuefi not found"
fi

# Unload module
echo ""
echo "Unloading hpuefi module..."
if lsmod | grep -q hpuefi; then
    rmmod hpuefi
    if [ $? -eq 0 ]; then
        echo "  Module unloaded successfully"
    else
        echo "ERROR: Failed to unload module"
        exit 1
    fi
else
    echo "  Module is not loaded"
fi

echo ""
echo "=========================================="
echo "Uninstallation completed successfully!"
echo "=========================================="
