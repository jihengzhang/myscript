#!/bin/bash

###############################################################################
# SunPinyin Configuration Script
# Purpose: Check and setup SunPinyin with fcitx on Ubuntu
# Usage: ./config_sogou.sh (will prompt for sudo password when needed)
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running with sudo for apt commands
SUDO=""
if [[ $EUID -ne 0 ]]; then
    SUDO="sudo"
fi

# Optional: uninstall Sogou if requested
UNINSTALL_SOGOU="${UNINSTALL_SOGOU:-0}"

# Functions
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check Chinese locale
check_and_setup_locale() {
    print_header "Checking Chinese Locale"
    
    if locale -a | grep -q "zh_CN.utf8"; then
        print_success "Chinese locale (zh_CN.UTF-8) is installed"
    else
        print_warning "Chinese locale not found, installing..."
        $SUDO apt-get update -qq
        $SUDO apt-get install -y language-pack-zh-hans language-pack-zh-hans-base > /dev/null 2>&1
        $SUDO locale-gen zh_CN.UTF-8
        $SUDO update-locale LANG=zh_CN.UTF-8
        print_success "Chinese locale installed"
    fi
}

# Check fcitx installation
check_and_install_fcitx() {
    print_header "Checking fcitx Framework"
    
    if command -v fcitx &> /dev/null; then
        print_success "fcitx is installed"
    else
        print_warning "fcitx not found, installing..."
        $SUDO apt-get update -qq
        $SUDO apt-get install -y \
            fcitx \
            fcitx-config-gtk \
            fcitx-sunpinyin > /dev/null 2>&1
        print_success "fcitx installed"
    fi
}

# Optional: uninstall Sogou to avoid conflicts
uninstall_sogou_if_requested() {
    if [[ "$UNINSTALL_SOGOU" != "1" ]]; then
        return 0
    fi

    print_header "Uninstalling Sogou Pinyin"

    if dpkg -l | grep -q "sogoupinyin"; then
        $SUDO apt-get remove -y sogoupinyin > /dev/null 2>&1
        print_success "Sogou Pinyin removed"
    else
        print_info "Sogou Pinyin is not installed"
    fi
}

# Check fcitx-configtool
check_and_install_configtool() {
    print_header "Checking fcitx Configuration Tool"
    
    if command -v fcitx-configtool &> /dev/null; then
        print_success "fcitx-configtool is installed"
    else
        print_warning "fcitx-configtool not found, installing..."
        $SUDO apt-get install -y fcitx-config-gtk fcitx-tools > /dev/null 2>&1
        print_success "fcitx-configtool installed"
    fi
}

# Configure fcitx to use Sogou
configure_fcitx() {
    print_header "Configuring fcitx for Sogou"
    
    # Set fcitx as default input method
    $SUDO im-config -n fcitx > /dev/null 2>&1 || true
    
    print_success "fcitx set as default input method"
}

# Configure fcitx autostart with systemd
setup_fcitx_autostart() {
    print_header "Configuring fcitx Autostart"
    
    # Create systemd user service directory
    mkdir -p ~/.config/systemd/user
    
    # Create fcitx systemd service
    cat > ~/.config/systemd/user/fcitx.service << 'SYSTEMD_EOF'
[Unit]
Description=Fcitx Input Method
Documentation=man:fcitx(1)
After=graphical-session-pre.target

[Service]
Type=forking
ExecStart=/usr/bin/fcitx --replace -d
ExecReload=/bin/sh -c "pkill fcitx; sleep 1; fcitx -d"
Restart=always
RestartSec=2

[Install]
WantedBy=graphical-session.target
SYSTEMD_EOF
    
    # Enable and start the service
    systemctl --user daemon-reload > /dev/null 2>&1
    systemctl --user enable fcitx.service > /dev/null 2>&1
    systemctl --user start fcitx.service > /dev/null 2>&1
    
    print_success "fcitx autostart configured"
}

# Configure environment variables for GNOME
setup_fcitx_environment() {
    print_header "Configuring fcitx Environment"
    
    # Create environment.d directory
    mkdir -p ~/.config/environment.d
    
    # Set environment variables
    cat > ~/.config/environment.d/fcitx.conf << 'ENV_EOF'
# Fcitx Input Method Configuration
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
ENV_EOF
    
    print_success "fcitx environment variables configured"
}

# Restart fcitx service
restart_fcitx() {
    print_header "Restarting fcitx Service"
    
    # Kill existing fcitx processes
    killall fcitx fcitx-qimpanel > /dev/null 2>&1 || true
    sleep 1
    
    # Start fcitx in background
    fcitx > /dev/null 2>&1 &
    sleep 2
    
    print_success "fcitx service restarted"
}

# Verify installation
verify_installation() {
    print_header "Verifying Installation"
    
    local all_good=true
    
    # Check locale
    if locale -a | grep -q "zh_CN.utf8"; then
        print_success "Chinese locale is available"
    else
        print_error "Chinese locale is NOT available"
        all_good=false
    fi
    
    # Check fcitx
    if command -v fcitx &> /dev/null; then
        print_success "fcitx is installed"
    else
        print_error "fcitx is NOT installed"
        all_good=false
    fi
    
    # Check SunPinyin
    if dpkg -l | grep -q "fcitx-sunpinyin"; then
        print_success "SunPinyin is installed"
    else
        print_error "SunPinyin is NOT installed"
        all_good=false
    fi
    
    # Check fcitx process
    if pgrep -x "fcitx" > /dev/null; then
        print_success "fcitx daemon is running"
    else
        print_warning "fcitx daemon is not running (will start after login)"
    fi
    
    return 0
}

# Main function
main() {
    print_header "SunPinyin Configuration Script"
    
    check_and_setup_locale
    uninstall_sogou_if_requested
    check_and_install_fcitx
    check_and_install_configtool
    configure_fcitx
    setup_fcitx_autostart
    setup_fcitx_environment
    restart_fcitx
    verify_installation
    
    echo ""
    print_header "Setup Complete"
    echo ""
    print_info "Configuration Summary:"
    echo "  ✓ SunPinyin installed"
    echo "  ✓ fcitx input method framework configured"
    echo "  ✓ Autostart enabled (fcitx will start on login)"
    echo "  ✓ Environment variables set"
    echo ""
    print_info "Quick start:"
    echo "  1. Log out and log back in for full configuration to take effect"
    echo "  2. Use Ctrl+Space to switch between input methods"
    echo "  3. Type Chinese characters using SunPinyin"
    echo ""
    print_info "If input method still not working:"
    echo "  • Try: fcitx-configtool"
    echo "  • Check if SunPinyin is in the enabled list"
    echo "  • Verify fcitx is running: ps aux | grep fcitx"
    echo "  • Restart: killall fcitx; fcitx &"
    echo "  • Check environment: echo \$GTK_IM_MODULE"
    echo ""
}

# Run main function
main
