# HP UEFI BIOS Flash Tools Installation Guide

This repository contains automated installation scripts for HP UEFI BIOS flashing tools on Linux systems.

## Overview

The installation includes two main components:
1. **hpuefi kernel module** - Required kernel driver for UEFI BIOS access
2. **hp-flash utilities** - Command-line tools for BIOS flashing and repository setup

## Prerequisites

- Root/sudo access
- Linux kernel headers installed (`sudo apt install linux-headers-$(uname -r)`)
- Build tools (`sudo apt install build-essential`)
- Supported HP server hardware

## Quick Start

### One-Command Installation

```bash
cd /home/tester/myscript
sudo bash install-all.sh
```

This master script will:
1. Build and install the hpuefi kernel module
2. Install hp-flash utilities
3. Create symbolic links for easy command access

### Manual Installation

If you prefer step-by-step installation:

#### Step 1: Install hpuefi Kernel Module

```bash
cd /home/tester/myscript/hpuefi-mod-3.06
sudo bash install.sh
```

This will:
- Build the hpuefi.ko kernel module
- Load the module into the running kernel
- Create /dev/hpuefi device node
- Install module to /lib/modules/$(uname -r)/extra/

#### Step 2: Install hp-flash Utilities

```bash
cd /home/tester/myscript/hp-flash-3.25_x86_64
sudo bash install.sh
```

This will:
- Install hp-flash and hp-repsetup to /opt/hp/hp-flash/
- Create necessary documentation and scripts

#### Step 3: Create Command Shortcuts (Optional)

```bash
sudo ln -sf /opt/hp/hp-flash/bin/hp-flash /usr/local/bin/hp-flash
sudo ln -sf /opt/hp/hp-flash/bin/hp-repsetup /usr/local/bin/hp-repsetup
```

## Available Commands

After installation, you can use:

- **hp-flash** - Flash BIOS firmware
- **hp-repsetup** - Setup BIOS repository

### Usage Examples

```bash
# Check hp-flash help
hp-flash --help

# Setup repository
hp-repsetup --help
```

## Directory Structure

```
/home/tester/myscript/
├── install-all.sh              # Master installation script
├── hpuefi-mod-3.06/           # Kernel module source
│   ├── install.sh             # Module installation script
│   ├── Makefile               # Build configuration
│   ├── hpuefi.c               # Module source code
│   └── mkdevhpuefi            # Device node creation script
└── hp-flash-3.25_x86_64/      # Flash utilities
    ├── install.sh             # Utilities installation script
    ├── bin/                   # Binary executables
    │   ├── hp-flash
    │   └── hp-repsetup
    └── docs/                  # Documentation
```

## Installation Locations

- **Kernel Module**: `/lib/modules/$(uname -r)/extra/hpuefi.ko`
- **Device Node**: `/dev/hpuefi`
- **Utilities**: `/opt/hp/hp-flash/`
- **Command Links**: `/usr/local/bin/hp-flash`, `/usr/local/bin/hp-repsetup`

## Verification

After installation, verify:

```bash
# Check if module is loaded
lsmod | grep hpuefi

# Check device node
ls -l /dev/hpuefi

# Check commands
which hp-flash
which hp-repsetup
```

## Uninstallation

To remove the hpuefi module:

```bash
cd /home/tester/myscript/hpuefi-mod-3.06
sudo bash uninstall.sh
```

To remove hp-flash utilities:

```bash
sudo rm -rf /opt/hp/hp-flash
sudo rm /usr/local/bin/hp-flash
sudo rm /usr/local/bin/hp-repsetup
```

## Important Notes

- The kernel module installation is **persistent** across reboots (installed to system module directory)
- The module must be loaded before using hp-flash utilities
- Requires HP server hardware with UEFI support
- Always backup important data before BIOS updates

## Troubleshooting

### Module not found error
```bash
# Rebuild module dependencies
sudo depmod -a
```

### Permission denied
```bash
# Ensure running with sudo
sudo bash install-all.sh
```

### Build failures
```bash
# Install required packages
sudo apt update
sudo apt install linux-headers-$(uname -r) build-essential
```

### Command not found after installation
```bash
# Use full path or add to PATH
/opt/hp/hp-flash/bin/hp-flash
# OR create symbolic links manually
sudo ln -sf /opt/hp/hp-flash/bin/hp-flash /usr/local/bin/hp-flash
```

## Script Features

All installation scripts have been enhanced with:
- ✅ Function-based error handling to prevent terminal exit
- ✅ Step-by-step progress indicators
- ✅ Comprehensive verification checks
- ✅ Detailed error messages
- ✅ Safe cleanup on failures

## Version Information

- **hpuefi-mod**: 3.06
- **hp-flash**: 3.25 (x86_64)
- **Kernel Compatibility**: Linux 6.8.0+ (tested on Ubuntu 22.04)

## License

These tools are provided by HP. Please refer to individual package documentation for licensing information.

## Support

For issues related to:
- **Installation scripts**: Check error messages and troubleshooting section
- **HP tools**: Refer to HP official documentation
- **Kernel module**: Check kernel logs with `dmesg | grep hpuefi`

---

**Last Updated**: 2024
**Maintainer**: System Administrator
