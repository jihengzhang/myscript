#!/usr/bin/env bash
# set -euo pipefail

"""
Ubuntu Initialization Script
Add multi-architecture support and improve installation reliability
2026-02-20
Major changes:
- Add hardware detection (arch, device type, GPU, memory)
- Support ARM64/aarch64 for Sogou, Clash, Miniconda, Edge, Chrome
- Replace ClashCross with Clash Verge Rev (better ARM64 support)
- Dynamically fetch latest Sogou download URL from official site
- Add -hwinfo flag to display system information
- Add -chrome option (Chrome on x86_64, Chromium on ARM64)
- Improve Miniconda with arch detection and conda-forge config
- Better error messages and user guidance for failed installations
- Update README with recent changes summary and Clash Verge URLs

Tested on: Ubuntu x86_64 and ARM64 (Jetson)
"""

SUDO=""
[[ $EUID -ne 0 ]] && SUDO="sudo"

APT_UPDATED=0
log() { printf '\n[%s] %s\n' "$(date +'%H:%M:%S')" "$*"; }
error() { printf '\n[%s] ERROR: %s\n' "$(date +'%H:%M:%S')" "$*" >&2; }

# Hardware info globals
HW_ARCH=""
HW_DEVICE_TYPE=""
HW_GPU_TYPE=""
HW_OS_VERSION=""
HW_MEMORY_GB=""

detect_hardware() {
	log "Detecting hardware configuration..."
	
	# Detect CPU architecture
	HW_ARCH=$(uname -m)
	
	# Detect device type (Jetson, PC, etc.)
	if [[ -f /etc/nv_tegra_release ]] || grep -qi "tegra" /proc/cpuinfo 2>/dev/null; then
		HW_DEVICE_TYPE="jetson"
	elif [[ -d /sys/class/net/wlan0 ]] && grep -qi "raspberry" /proc/cpuinfo 2>/dev/null; then
		HW_DEVICE_TYPE="rpi"
	else
		HW_DEVICE_TYPE="pc"
	fi
	
	# Detect GPU type
	if lspci 2>/dev/null | grep -qi nvidia; then
		HW_GPU_TYPE="nvidia"
	elif lspci 2>/dev/null | grep -qi amd; then
		HW_GPU_TYPE="amd"
	elif lspci 2>/dev/null | grep -qi intel; then
		HW_GPU_TYPE="intel"
	elif [[ "$HW_DEVICE_TYPE" == "jetson" ]]; then
		HW_GPU_TYPE="tegra"
	else
		HW_GPU_TYPE="none"
	fi
	
	# Detect OS version
	if [[ -f /etc/os-release ]]; then
		HW_OS_VERSION=$(grep VERSION_ID /etc/os-release | cut -d= -f2 | tr -d '"')
	fi
	
	# Detect memory
	HW_MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
	
	log "Hardware detected:"
	log "  Architecture: $HW_ARCH"
	log "  Device Type:  $HW_DEVICE_TYPE"
	log "  GPU Type:     $HW_GPU_TYPE"
	log "  OS Version:   $HW_OS_VERSION"
	log "  Memory:       ${HW_MEMORY_GB}GB"
}

check_internet() {
	log "Checking internet connectivity..."
	if ping -c 1 8.8.8.8 &>/dev/null || ping -c 1 1.1.1.1 &>/dev/null; then
		log "Internet connection OK"
		return 0
	else
		error "No internet connection detected"
		error "Please check your network and try again"
		return 1
	fi
}

apt_update_once() {
	[[ $APT_UPDATED -eq 1 ]] && return
	log "Updating apt indices..."
	$SUDO apt update -qq
	APT_UPDATED=1
}
apt_install() {
	apt_update_once
	log "Installing package(s): $*"
	$SUDO apt install -y "$@"
}

enable_ssh() {
	log "Enabling OpenSSH server..."
	apt_install openssh-server
	$SUDO systemctl enable --now ssh.service
	$SUDO ufw allow 22/tcp >/dev/null 2>&1 || true
}

install_sogou() {
	log "Installing Sogou Pinyin (fcitx) for $HW_ARCH..."
	
	# Ensure curl is installed for fetching download URLs
	apt_install curl
	
	# Determine architecture pattern for URL matching
	local arch_pattern
	case "$HW_ARCH" in
		x86_64)
			arch_pattern="amd64"
			;;
		aarch64|arm64)
			arch_pattern="arm64"
			;;
		*)
			error "Sogou Pinyin: Unsupported architecture: $HW_ARCH"
			log "Visit https://shurufa.sogou.com/linux for supported architectures"
			return 1
			;;
	esac
	
	# Always fetch the latest download URL dynamically from Sogou's official website
	local download_url
	if [[ -n "${SOGOU_DEB_URL}" ]]; then
		log "Using custom SOGOU_DEB_URL from environment: ${SOGOU_DEB_URL}"
		download_url="${SOGOU_DEB_URL}"
	else
		log "Fetching latest Sogou Pinyin download URL from official website..."
		download_url=$(curl -sL --max-time 10 "https://shurufa.sogou.com/linux" 2>/dev/null | grep -oP "https://[^\"']*${arch_pattern}\.deb" | head -1)
		
		if [[ -n "$download_url" ]]; then
			log "Successfully fetched latest URL: $download_url"
		else
			error "Failed to fetch download URL from https://shurufa.sogou.com/linux"
			log "Please check your network connection or download manually from the website"
			log "You can also place a sogou*.deb file in the current directory"
			log "Or set SOGOU_DEB_URL environment variable with a direct download link"
			return 1
		fi
	fi
	
	apt_install fcitx-bin fcitx-config-gtk fcitx-table libqt5qml5 libqt5quick5 libqt5quickwidgets5 qml-module-qtquick2 libgsettings-qt1
	
	local deb
	
	# Try to find local sogou*.deb file first
	local local_deb
	local_deb=$(find . -path ./HP -prune -o -name "sogou*.deb" -type f -print 2>/dev/null | head -n1)
	
	if [[ -n "$local_deb" && -f "$local_deb" ]]; then
		log "Found local Sogou package: $local_deb"
		deb="$local_deb"
	else
		log "Downloading Sogou Pinyin from: $download_url"
		deb="$(mktemp --suffix=.deb)"
		# Use browser-like headers to avoid 403 errors from CDN
		if ! wget --timeout=60 --tries=2 -q --show-progress \
			--user-agent="Mozilla/5.0 (X11; Linux ${HW_ARCH}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
			--referer="https://shurufa.sogou.com/linux" \
			--header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
			--header="Accept-Language: zh-CN,zh;q=0.9,en;q=0.8" \
			"$download_url" -O "$deb"; then
			error "Failed to download Sogou Pinyin package from CDN"
			rm -f "$deb"
			log ""
			log "The CDN may have anti-bot protection or the link expired."
			log "Please download manually using one of these methods:"
			log ""
			log "Method 1 - Download with browser:"
			log "  1. Open https://shurufa.sogou.com/linux in your browser"
			log "  2. Click the ${arch_pattern} download button"
			log "  3. Save the .deb file to: $PWD"
			log "  4. Run this script again: . ./ubuntu_init.sh -sogou"
			log ""
			log "Method 2 - Use direct download link (if available):"
			log "  wget '$download_url' -O sogou_pinyin.deb"
			log ""
			return 1
		fi
		log "Download completed successfully"
	fi
	
	if ! $SUDO dpkg -i "$deb"; then
		log "Resolving Sogou dependencies..."
		apt_install -f
		$SUDO dpkg -i "$deb"
	fi
	
	# Clean up temp file if we created one
	[[ "$deb" == /tmp/* ]] && rm -f "$deb"
	
	log "Configuring fcitx to use Sogou Pinyin as default..."
	# Set fcitx as default input method framework
	im-config -n fcitx 2>/dev/null || true

	# Ensure fcitx env vars are loaded for GUI apps (including VS Code)
	mkdir -p ~/.config/environment.d
	cat > ~/.config/environment.d/fcitx.conf <<-'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
INPUT_METHOD=fcitx
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=ibus
EOF
	
	# Configure fcitx to use Sogou Pinyin
	mkdir -p ~/.config/fcitx
	cat > ~/.config/fcitx/profile <<-'EOF'
	[Profile]
	FullWidthPuncAfterNumber=True
	RemindModeDisablePaging=True
	ShareStateAmongWindow=NoState
	DefaultInputMethod=sogoupinyin
	
	[Profile/EnabledIMList]
	0=fcitx-keyboard-us:True
	1=sogoupinyin:True
	EOF
	
	# Set fcitx to autostart
	mkdir -p ~/.config/autostart
	cp /usr/share/applications/fcitx.desktop ~/.config/autostart/ 2>/dev/null || true
	
	log "Sogou Pinyin installed and configured. Please reboot to use Sogou input method."
}

install_clash_verge() {
	log "Installing Clash Verge..."
	apt_install curl wget jq
	
	# Determine appropriate download URL based on architecture
	local download_url
	local file_ext
	local install_method
	
	case "$HW_ARCH" in
		x86_64)
			# Use environment variable or fallback to hardcoded AppImage URL
			if [[ -n "$CLASH_VERGE_URL" ]]; then
				download_url="$CLASH_VERGE_URL"
				file_ext=".AppImage"
				install_method="appimage"
			else
				# Try to get latest release from clash-verge-rev (has better support)
				log "Fetching latest Clash Verge release info..."
				local latest_deb
				latest_deb=$(curl -s https://api.github.com/repos/clash-verge-rev/clash-verge-rev/releases/latest | grep "browser_download_url.*amd64.deb\"" | cut -d'"' -f4 | head -1)
				
				if [[ -n "$latest_deb" ]]; then
					download_url="$latest_deb"
					file_ext=".deb"
					install_method="deb"
				else
					# Fallback to known AppImage URL
					download_url="https://github.com/zzzgydi/clash-verge/releases/download/v1.3.8/clash-verge_1.3.8_amd64.AppImage"
					file_ext=".AppImage"
					install_method="appimage"
				fi
			fi
			;;
		aarch64|arm64)
			# ARM64: use .deb from clash-verge-rev (has official ARM64 support)
			log "Fetching latest Clash Verge release info for ARM64..."
			local latest_arm_deb
			latest_arm_deb=$(curl -s https://api.github.com/repos/clash-verge-rev/clash-verge-rev/releases/latest | grep "browser_download_url.*arm64.deb\"" | cut -d'"' -f4 | head -1)
			
			if [[ -n "$latest_arm_deb" ]]; then
				download_url="$latest_arm_deb"
				file_ext=".deb"
				install_method="deb"
			elif [[ -n "$CLASH_VERGE_URL" ]]; then
				download_url="$CLASH_VERGE_URL"
				file_ext=".AppImage"
				install_method="appimage"
			else
				error "No ARM64 build found for Clash Verge"
				error "Set CLASH_VERGE_URL environment variable to specify a custom download URL"
				return 1
			fi
			;;
		*)
			error "Clash Verge: Unsupported architecture: $HW_ARCH"
			return 1
			;;
	esac
	
	log "Downloading Clash Verge from $download_url"
	
	local temp_file
	temp_file=$(mktemp --suffix="$file_ext")
	
	# Download file
	if ! wget -q --show-progress "$download_url" -O "$temp_file"; then
		error "Failed to download Clash Verge"
		rm -f "$temp_file"
		return 1
	fi
	
	# Install based on file type
	if [[ "$install_method" == "deb" ]]; then
		log "Installing Clash Verge .deb package..."
		if ! $SUDO dpkg -i "$temp_file"; then
			log "Resolving dependencies..."
			apt_install -f
			$SUDO dpkg -i "$temp_file"
		fi
		rm -f "$temp_file"
		log "Clash Verge installed successfully"
		log "Launch from Applications menu or run: clash-verge"
	else
		# AppImage installation
		local app_dir="$HOME/Applications"
		mkdir -p "$app_dir"
		
		local appimage_path="$app_dir/clash-verge.AppImage"
		mv "$temp_file" "$appimage_path"
		chmod +x "$appimage_path"
		
		# Create desktop entry
		mkdir -p ~/.local/share/applications
		cat > ~/.local/share/applications/clash-verge.desktop <<EOF
[Desktop Entry]
Name=Clash Verge
Comment=A Clash GUI based on Tauri
Exec=$appimage_path
Icon=clash-verge
Terminal=false
Type=Application
Categories=Network;
EOF
		
		log "Clash Verge installed at $appimage_path"
		log "Launch from Applications menu or run: $appimage_path"
	fi
}


install_vscode() {
	log "Installing Visual Studio Code..."
	
	# Clean up conflicting VS Code repository configurations
	$SUDO rm -f /etc/apt/sources.list.d/vscode.list
	$SUDO rm -f /etc/apt/sources.list.d/vscode.sources
	$SUDO rm -f /usr/share/keyrings/microsoft.gpg
	$SUDO rm -f /etc/apt/keyrings/packages.microsoft.gpg
	
	apt_install curl wget gpg apt-transport-https
	$SUDO install -d -m 0755 /etc/apt/keyrings
	wget -qO- https://packages.microsoft.com/keys/microsoft.asc | $SUDO gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | $SUDO tee /etc/apt/sources.list.d/vscode.list >/dev/null
	
	APT_UPDATED=0
	apt_install code
	log "Visual Studio Code installed."
}

enable_remote_desktop() {
	log "Enabling XRDP remote desktop..."
	apt_install xrdp
	$SUDO systemctl enable --now xrdp.service
	$SUDO ufw allow 3389/tcp >/dev/null 2>&1 || true
}



setup_static_ip() {
	log "Configuring static IP for Wired ethernet 0..."
	# Get the first active ethernet connection name
	local connection_name
	connection_name=$($SUDO nmcli -t -f NAME,TYPE connection show --active | grep ethernet | head -n1 | cut -d: -f1)
	
	if [[ -z "$connection_name" ]]; then
		log "No active ethernet connection found. Listing all connections:"
		$SUDO nmcli connection show
		return 1
	fi
	
	log "Configuring connection: $connection_name"
	$SUDO nmcli connection modify "$connection_name" ipv4.addresses 10.190.63.138/22
	$SUDO nmcli connection modify "$connection_name" ipv4.gateway 10.190.60.1
	$SUDO nmcli connection modify "$connection_name" ipv4.dns 10.56.56.56
	$SUDO nmcli connection modify "$connection_name" ipv4.method manual
	$SUDO nmcli connection up "$connection_name"
	
	log "Static IP configured: 10.190.63.138/22, gateway: 10.190.60.1, DNS: 10.56.56.56"
}

install_edge() {
	log "Installing Microsoft Edge for $HW_ARCH..."
	
	# Check architecture support
	case "$HW_ARCH" in
		x86_64)
			local arch_str="amd64"
			;;
		aarch64|arm64)
			# Check if ARM64 packages are available
			log "Checking ARM64 package availability..."
			if ! curl -s https://packages.microsoft.com/repos/edge/dists/stable/main/binary-arm64/Packages 2>/dev/null | grep -q "Package:"; then
				log "Microsoft Edge ARM64 packages not currently available in official repository"
				log "You can try installing Chromium or Chrome instead (which support ARM64)"
				log "  sudo apt install chromium-browser"
				return 0
			fi
			local arch_str="arm64"
			;;
		*)
			error "Microsoft Edge: Unsupported architecture: $HW_ARCH"
			return 1
			;;
	esac
	
	apt_install curl wget gpg apt-transport-https
	
	curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | $SUDO gpg --dearmor -o /usr/share/keyrings/microsoft-edge.gpg
	echo "deb [arch=$arch_str signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" | $SUDO tee /etc/apt/sources.list.d/microsoft-edge.list
	
	APT_UPDATED=0
	apt_install microsoft-edge-stable
	log "Microsoft Edge installed."
}


install_git() {
	log "Installing Git..."
	apt_install git
	log "Git installed. Version: $(git --version)"

	# Configure git proxy if system proxy is detected
	local proxy_host="127.0.0.1"
	local proxy_port="7897"
	local proxy_url="http://${proxy_host}:${proxy_port}"

	# Check if proxy port is listening
	if ss -tlnp 2>/dev/null | grep -q ":${proxy_port}" || \
	   nc -z -w1 "${proxy_host}" "${proxy_port}" 2>/dev/null; then
		log "System proxy detected at ${proxy_url}, configuring git..."
		git config --global http.proxy  "${proxy_url}"
		git config --global https.proxy "${proxy_url}"
		log "Git proxy set: http.proxy / https.proxy -> ${proxy_url}"
	else
		log "Proxy port ${proxy_port} not active; skipping git proxy configuration."
	fi
}

install_chrome() {
	log "Installing Google Chrome for $HW_ARCH..."
	
	# Determine architecture string for Chrome
	local arch_str
	case "$HW_ARCH" in
		x86_64)
			arch_str="amd64"
			;;
		aarch64|arm64)
			log "Google Chrome does not officially support ARM64 Linux"
			log "Installing Chromium as an open-source alternative..."
			apt_install chromium-browser
			log "Chromium installed. You can launch it from Applications menu or run: chromium-browser"
			return 0
			;;
		*)
			error "Google Chrome: Unsupported architecture: $HW_ARCH"
			return 1
			;;
	esac
	
	apt_install curl wget gpg apt-transport-https
	
	# Add Google Chrome repository
	curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | $SUDO gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
	echo "deb [arch=$arch_str signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | $SUDO tee /etc/apt/sources.list.d/google-chrome.list
	
	APT_UPDATED=0
	apt_install google-chrome-stable
	log "Google Chrome installed."
}

install_miniconda() {
	log "Installing Miniconda..."
	apt_install curl wget
	
	# Use detected architecture
	local arch="$HW_ARCH"
	local installer_url
	case "$arch" in
		x86_64)
			installer_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
			;;
		aarch64|arm64)
			installer_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"
			;;
		*)
			error "Unsupported architecture: $arch"
			return 1
			;;
	esac
	
	log "Target architecture: $arch"
	local installer="/tmp/Miniconda3-latest-Linux-${arch}.sh"
	local install_dir="$HOME/miniconda3"
	local conda_bin="$install_dir/bin/conda"
	local installer_args=("-b" "-p" "$install_dir")

	if [[ -d "$install_dir" ]]; then
		if [[ -x "$conda_bin" ]]; then
			log "Existing Miniconda detected, updating in place..."
			installer_args=("-u" "-b" "-p" "$install_dir")
		else
			log "Broken Miniconda installation detected, removing $install_dir..."
			rm -rf "$install_dir"
		fi
	fi
	
	log "Downloading Miniconda from $installer_url"
	wget -q --show-progress "$installer_url" -O "$installer"
	bash "$installer" "${installer_args[@]}"
	rm -f "$installer"
	
	# Initialize conda
	"$conda_bin" init bash
	
	# Configure conda to use conda-forge
	"$conda_bin" config --set channel_priority flexible 2>/dev/null || true
	"$conda_bin" config --set auto_activate_base false 2>/dev/null || true
	"$conda_bin" config --remove channels defaults 2>/dev/null || true
	"$conda_bin" config --add channels conda-forge 2>/dev/null || true
	
	# Get installed Python version
	local py_version=$("$conda_bin" run python --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
	
	log "Miniconda installed at $install_dir with Python $py_version"
	log "To create a custom Python environment, use: conda create -n myenv python=3.11"
	log "Restart your terminal or run: source ~/.bashrc"
}

enable_fuse2() {
    log "Enabling FUSE2 for AppImage support..."
    apt_install fuse libfuse2

    log "Configuring FUSE2..."
    if ! grep -q "user_allow_other" /etc/fuse.conf; then
        echo "user_allow_other" | $SUDO tee -a /etc/fuse.conf >/dev/null
    fi

    log "FUSE2 enabled successfully."
}

show_help() {
	cat <<'EOF'
Usage: ubuntu_init.sh [options]

Options:
  -h        Show this help
  -hwinfo   Show hardware information and exit
  -ssh      Enable SSH server
  -sogou    Install Sogou Pinyin (fcitx, auto-fetches latest URL for x86_64/ARM64)
  -clash    Install Clash Verge (AppImage, auto-detects arch)
  -code     Install Visual Studio Code
  -remote   Enable XRDP remote desktop
  -ip       Setup static IP (10.190.63.138/22)
  -edge     Install Microsoft Edge (x86_64 only, suggests alternatives on ARM64)
  -chrome   Install Chrome (x86_64) or Chromium (ARM64 alternative)
  -git      Install Git
  -conda    Install Miniconda (auto-detects arch, uses latest Python)
  -fuse2    Enable FUSE2 for AppImage support
  -all      Run all tasks

NOTE: Script auto-detects hardware and adjusts installations accordingly.

Env overrides:
  SOGOU_DEB_URL, CLASH_VERGE_URL, DEFAULT_NVIDIA_DRIVER
  MINICONDA_FORCE_REINSTALL=1 (force clean reinstall)
EOF
}

# [[ $# -eq 0 ]] && { show_help; exit 0; }  terminal will exit
[[ $# -eq 0 ]] && { show_help ; }

# Check for hwinfo flag first
if [[ "$1" == "-hwinfo" ]]; then
	detect_hardware
	return 0
fi

# Check internet connectivity
check_internet || exit 1

# Detect hardware before any installations
detect_hardware

declare -A run_flags=()
run_all=false

# Handle long options
for arg in "$@"; do
	case "$arg" in
		-ssh) run_flags["ssh"]=1; shift ;;
		-sogou) run_flags["sogou"]=1; shift ;;
		-clash) run_flags["clash"]=1; shift ;;
		-code) run_flags["code"]=1; shift ;;
		-remote) run_flags["remote"]=1; shift ;;
		-ip) run_flags["ip"]=1; shift ;;
		-edge) run_flags["edge"]=1; shift ;;
		-chrome) run_flags["chrome"]=1; shift ;;
		-git) run_flags["git"]=1; shift ;;
		-conda) run_flags["conda"]=1; shift ;;
		-fuse2) run_flags["fuse2"]=1; shift ;;
		-all) run_all=true; shift ;;
		-hwinfo) ;; # Already handled
		-h) show_help; return 0 ;;
		*) ;;
	esac
done

if $run_all; then
	run_flags=( ["ssh"]=1 ["sogou"]=1 ["clash"]=1 ["code"]=1 ["remote"]=1 ["ip"]=1 ["edge"]=1 ["chrome"]=1 ["git"]=1 ["conda"]=1 ["fuse2"]=1 )
fi
[[ ${#run_flags[@]} -eq 0 ]] && { show_help; return 0; }

# Execute tasks in defined order
for step in ssh sogou clash code remote nvidia ip edge chrome git conda fuse2; do
	if [[ "${run_flags[$step]}" == "1" ]]; then
		case "$step" in
			ssh) enable_ssh ;;
			sogou) install_sogou ;;
			clash) install_clash_verge ;;
			code) install_vscode ;;
			remote) enable_remote_desktop ;;
				ip) setup_static_ip ;;
			edge) install_edge ;;
			chrome) install_chrome ;;
			git) install_git ;;
			conda) install_miniconda ;;
			fuse2) enable_fuse2 ;;
		esac
	fi
done