# Ubuntu Initialization Scripts

This repository contains automated scripts for setting up a fresh Ubuntu system with essential tools and configurations.

## Recent Updates (Feb 2026)

**Multi-Architecture Support:** The script now automatically detects hardware and supports both x86_64 and ARM64 architectures (including Jetson devices).

**Key Improvements:**
- **Hardware Detection**: Auto-detects CPU architecture, device type, GPU, OS version, and memory
- **Smart Sogou Installation**: Dynamically fetches latest download URL for correct architecture
- **Clash Verge**: Replaced ClashCross with Clash Verge Rev (better ARM64 support)
- **Chrome Support**: Added `-chrome` option (installs Chromium on ARM64 as alternative)
- **Enhanced Miniconda**: Auto-detects architecture and uses latest Python version
- **Better Error Handling**: Improved user guidance when installations fail
- **New `-hwinfo` flag**: Display system hardware information

## Files

### ubuntu_init.sh
Comprehensive Ubuntu system initialization script with support for installing and configuring multiple services and applications.

clashcross： include person subscripe info:
https://su.gwzxwk.com/api/v1/client/subscribe?token=0433b69986e2fa466e05349395f85fc1 


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
```git

**ARM 64**

use clash verge to replace clashcross
 - https://github.com/zzzgydi/clash-verge/releases/download/v1.3.8/clash-verge_1.3.8_amd64.AppImage
tester@jetson:~/AI_Tools/myscript$  curl -s https://api.github.com/repos/clash-verge-rev/clash-verge-rev/releases/latest | grep "browser_download_url" | cut -d'"' -f4 | head -15
https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge-2.4.6-1.aarch64.rpm
https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge-2.4.6-1.armhfp.rpm
https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge-2.4.6-1.x86_64.rpm
https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge-2.4.6-1.x86_64.rpm.sig
https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge_2.4.6_aarch64.dmg
https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge_2.4.6_amd64.deb
https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge_2.4.6_amd64.deb.sig
https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge_2.4.6_arm64-setup.exe
https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge_2.4.6_arm64-setup.exe.sig
https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge_2.4.6_arm64.deb
https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge_2.4.6_arm64_fixed_webview2-setup.exe
https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge_2.4.6_arm64_fixed_webview2-setup.exe.sig
https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge_2.4.6_armhf.deb
https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge_2.4.6_x64-setup.exe
https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge_2.4.6_x64-setup.exe.sig

use ARM64 version sogou
https://shurufa.sogou.com/linux/guide 

https://ime-sec.gtimg.com/202602210541/50992d12d3d1ce0eb8ef342ae03b002f/pc/dl/gzindex/1680521473/sogoupinyin_4.2.1.145_arm64.deb 
 - 

***clash***

https://github.com/clash-verge-rev/clash-verge-rev/releases 

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

## Git SSH 设置指南

正确配置 Git 和 SSH 访问是使用 GitHub 和其他 Git 服务的关键。以下是完整的设置步骤：

### 1. 生成 SSH 密钥

```bash
# 使用 Ed25519 算法生成密钥（推荐，更安全）
ssh-keygen -t ed25519 -C "your_email@example.com"

# 或使用 RSA 算法（兼容性更好）
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

按照提示操作：
```
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/username/.ssh/id_ed25519): 
# 直接按 Enter 使用默认路径

Enter passphrase (empty for no passphrase): 
# 输入密码（可选，建议设置）

Enter same passphrase again:
# 再次确认密码
```

### 2. 验证密钥生成

```bash
# 查看 SSH 密钥文件
ls -la ~/.ssh/

# 查看公钥内容（用于添加到 GitHub）
cat ~/.ssh/id_ed25519.pub
```

### 3. 配置全局 Git 用户信息

```bash
# 设置用户名
git config --global user.name "Your Name"

# 设置邮箱
git config --global user.email "your_email@example.com"

# 验证配置
git config --global --list
```

### 4. 添加公钥到 GitHub

1. 复制公钥内容：
```bash
cat ~/.ssh/id_ed25519.pub
```

2. 登录 GitHub，进入设置：
   - Settings → SSH and GPG keys
   - 点击 "New SSH key"
   - 粘贴公钥内容并保存

### 5. 测试 SSH 连接

```bash
ssh -T git@github.com
```

成功连接会显示：
```
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

### 6. 使用 SSH 克隆仓库

```bash
# 使用 SSH 地址克隆
git clone git@github.com:username/repo.git
cd repo

# 或修改已存在的仓库为 SSH 访问
git remote set-url origin git@github.com:username/repo.git

# 验证远程配置
git remote -v
```

### 常见问题排查

```bash
# 增加 SSH 调试信息
ssh -vT git@github.com

# 如果权限问题，检查密钥文件权限
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# 启动 SSH agent（如果密钥有密码）
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

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
