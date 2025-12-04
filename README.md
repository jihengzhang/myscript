# Ubuntu Initialization Scripts

This repository contains automated scripts for setting up a fresh Ubuntu system with essential tools and configurations.

## Files

### ubuntu_init.sh
Comprehensive Ubuntu system initialization script with support for installing and configuring multiple services and applications.

**Usage:**
```bash
./ubuntu_init.sh [options]

# Show help
./ubuntu_init.sh -h

# Individual tasks
./ubuntu_init.sh -ssh        # Enable SSH server
./ubuntu_init.sh -sogou      # Install Sogou Pinyin (fcitx)
./ubuntu_init.sh -clash      # Install ClashCross (Snap)
./ubuntu_init.sh -code       # Install Visual Studio Code
./ubuntu_init.sh -remote     # Enable XRDP remote desktop
./ubuntu_init.sh -nvidia     # Install NVIDIA driver
./ubuntu_init.sh -ip         # Setup static IP
./ubuntu_init.sh -edge       # Install Microsoft Edge
./ubuntu_init.sh -git        # Install Git
./ubuntu_init.sh -conda      # Install Miniconda with Python 3.11

# Multiple tasks
./ubuntu_init.sh -ssh -git -code

# All tasks
./ubuntu_init.sh -all
```

**Features:**
- SSH server setup
- Sogou Pinyin input method with fcitx auto-configuration
- ClashCross via Snap Store
- VS Code installation with repository cleanup
- XRDP remote desktop
- NVIDIA driver installation
- Static IP configuration with auto-detection
- Microsoft Edge browser
- Git version control
- Miniconda with Python 3.11
- Error handling and dependency resolution
- Quiet apt updates for faster execution

### git_init.sh
Helper script to initialize a local git repository and push to GitHub.

**Usage:**
```bash
# Show help
./git_init.sh -h

# Initialize and push to GitHub
./git_init.sh https://github.com/user/repo.git

# With custom commit message
./git_init.sh https://github.com/user/repo.git "Add initial files"
```

**Features:**
- Git repository initialization
- User configuration
- Automatic file staging
- Commit creation
- GitHub remote setup
- HTTPS credential storage
- Automatic push to main/master branch

## Prerequisites

- Ubuntu 20.04+ (tested on Ubuntu 22.04)
- `bash` shell
- Internet connection
- `sudo` privileges for most tasks
- GitHub account (for git_init.sh)

## Installation

Clone this repository:
```bash
git clone https://github.com/jihengzhang/myscript.git
cd myscript
chmod +x ubuntu_init.sh git_init.sh
```

## Examples

### Fresh Ubuntu Setup
```bash
# Install all essentials
./ubuntu_init.sh -all

# Or selectively
./ubuntu_init.sh -ssh -code -git -conda
```

### Quick Git Setup
```bash
# Initialize your project and push to GitHub
./git_init.sh https://github.com/yourusername/yourrepo.git "Initial commit"
```

## Configuration

### Static IP (Option -ip)
The `-ip` option configures:
- IP: 10.190.63.138
- Netmask: 255.255.252.0 (/22)
- Gateway: 10.190.60.1
- DNS: 10.56.56.56

To modify these values, edit the `setup_static_ip()` function in `ubuntu_init.sh`.

### Environment Variables
```bash
# Override Sogou Pinyin URL
SOGOU_DEB_URL="https://custom-url.com/sogoupinyin.deb" ./ubuntu_init.sh -sogou

# Override NVIDIA driver
DEFAULT_NVIDIA_DRIVER="nvidia-driver-550" ./ubuntu_init.sh -nvidia
```

## Troubleshooting

### MS Office Repository Conflict
If you see this error:
```
E: Conflicting values set for option Signed-By regarding source...
```

Run:
```bash
sudo rm -f /etc/apt/sources.list.d/vscode.list /usr/share/keyrings/microsoft.gpg
sudo apt update
```

### Git Push Fails
- Check internet connection
- Verify GitHub repository URL
- Ensure you have write access to the repository
- Check GitHub rate limiting

### Sogou Download Fails
Download URL may be outdated. Visit https://shurufa.sogou.com/linux to get the latest URL and use:
```bash
SOGOU_DEB_URL="https://new-url-here" ./ubuntu_init.sh -sogou
```

## License

MIT License - feel free to use and modify for your needs.

## Contributing

Pull requests and suggestions are welcome!

## Author

jihengzhang
