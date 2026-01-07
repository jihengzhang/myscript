#!/usr/bin/env bash
# set -euo pipefail

SOGOU_DEB_URL="${SOGOU_DEB_URL:-https://cdn2.shouji.sogou.com/dl/index/1702590414/sogoupinyin_4.2.1.145_amd64.deb}"

SUDO=""
[[ $EUID -ne 0 ]] && SUDO="sudo"

APT_UPDATED=0
log() { printf '\n[%s] %s\n' "$(date +'%H:%M:%S')" "$*"; }
error() { printf '\n[%s] ERROR: %s\n' "$(date +'%H:%M:%S')" "$*" >&2; }

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
	log "Installing Sogou Pinyin (fcitx)..."
	apt_install curl fcitx-bin fcitx-config-gtk fcitx-table libqt5qml5 libqt5quick5 libqt5quickwidgets5 qml-module-qtquick2 libgsettings-qt1
	
	local deb
	
	# Try to find local sogou*.deb file first
	local local_deb
	local_deb=$(find . -path ./HP -prune -o -name "sogou*.deb" -type f -print 2>/dev/null | head -n1)
	
	if [[ -n "$local_deb" && -f "$local_deb" ]]; then
		log "Found local Sogou package: $local_deb"
		deb="$local_deb"
	else
		log "No local sogou*.deb file found, attempting download from $SOGOU_DEB_URL"
		deb="$(mktemp --suffix=.deb)"
		if ! curl -fsSL --max-redirs 100 "$SOGOU_DEB_URL" -o "$deb"; then
			log "Failed to download Sogou Pinyin package"
			rm -f "$deb"
			log "No local sogou*.deb file found and download failed"
			log "Please download manually from https://shurufa.sogou.com/linux and install with: sudo dpkg -i sogoupinyin_*_amd64.deb and put it into folder package"
			return 1
		fi
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

install_clashcross() {
	log "Installing ClashCross from Snap Store..."
	apt_install snapd
	$SUDO systemctl enable --now snapd.socket
	$SUDO snap install clash-for-windows
	log "ClashCross installed via Snap."
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
	log "Installing Microsoft Edge..."
	apt_install curl wget gpg apt-transport-https
	
	curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | $SUDO gpg --dearmor -o /usr/share/keyrings/microsoft-edge.gpg
	echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" | $SUDO tee /etc/apt/sources.list.d/microsoft-edge.list
	
	APT_UPDATED=0
	apt_install microsoft-edge-stable
	log "Microsoft Edge installed."
}


install_git() {
	log "Installing Git..."
	apt_install git
	log "Git installed. Version: $(git --version)"
}

install_miniconda() {
	log "Installing Miniconda with Python 3.11..."
	apt_install curl wget
	
	local installer="/tmp/Miniconda3-latest-Linux-x86_64.sh"
	local install_dir="$HOME/miniconda3"
	
	wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O "$installer"
	bash "$installer" -b -p "$install_dir"
	rm -f "$installer"
	
	# Initialize conda
	"$install_dir/bin/conda" init bash
	
	# Create environment with Python 3.11
	"$install_dir/bin/conda" create -n base python=3.11 -y
	
	log "Miniconda installed at $install_dir"
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
  -ssh      Enable SSH server
  -sogou    Install Sogou Pinyin (fcitx)
  -clash    Install ClashCross (Snap)
  -code     Install Visual Studio Code
  -remote   Enable XRDP remote desktop
  -ip       Setup static IP (10.190.63.138/22)
  -edge     Install Microsoft Edge
  -git      Install Git
  -conda    Install Miniconda with Python 3.11
  -fuse2    Enable FUSE2 for AppImage support
  -all      Run all tasks

Env overrides:
  SOGOU_DEB_URL, CLASHCROSS_DEB_URL, DEFAULT_NVIDIA_DRIVER
EOF
}

# [[ $# -eq 0 ]] && { show_help; exit 0; }  terminal will exit
[[ $# -eq 0 ]] && { show_help ; }

# Check internet connectivity
check_internet || exit 1

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
		-git) run_flags["git"]=1; shift ;;
		-conda) run_flags["conda"]=1; shift ;;
		-fuse2) run_flags["fuse2"]=1; shift ;;
		-all) run_all=true; shift ;;
		-h) show_help; return 0 ;;
		*) ;;
	esac
done

if $run_all; then
	run_flags=( ["ssh"]=1 ["sogou"]=1 ["clash"]=1 ["code"]=1 ["remote"]=1 ["ip"]=1 ["edge"]=1 ["git"]=1 ["fuse2"]=1 )
fi
[[ ${#run_flags[@]} -eq 0 ]] && { show_help; return 0; }

# Execute tasks in defined order
for step in ssh sogou clash code remote nvidia ip edge git conda fuse2; do
	if [[ "${run_flags[$step]}" == "1" ]]; then
		case "$step" in
			ssh) enable_ssh ;;
			sogou) install_sogou ;;
			clash) install_clashcross ;;
			code) install_vscode ;;
			remote) enable_remote_desktop ;;
				ip) setup_static_ip ;;
			edge) install_edge ;;
			git) install_git ;;
			conda) install_miniconda ;;
			fuse2) enable_fuse2 ;;
		esac
	fi
done
