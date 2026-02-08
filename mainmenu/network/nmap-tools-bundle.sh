#!/bin/bash
# ---
# name: "nmap-tools-bundle"
# description: "Nmap, Zenmap GUI, and nmapUnleashed scanning suite"
# version: "1.0.0"
# author: "alistairhendersoninfo"
# type: install
# root: true
# order: 9
# hidden: false
# installed: false
# check_command: "nmap --version"
# check_path: "/usr/bin/nmap"
# uninstall: ""
# dependencies:
#   - curl
#   - git
# tags:
#   - network
#   - scanner
#   - nmap
#   - zenmap
#   - security
# ---

#######################################
# NMAP TOOLS BUNDLE INSTALLER
# Installs: Nmap, Zenmap, nmapUnleashed
# Supports: Ubuntu (apt) and macOS (Homebrew)
#######################################

set -euo pipefail

# Determine script location and menu root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"

# Setup logging
LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()    { echo -e "${CYAN}[STEP]${NC} $1"; }

# Check if running as root when required
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Update the installed status in this script's YAML header
mark_installed() {
    local status="${1:-true}"
    sed -i "s/^# installed: .*/# installed: $status/" "${BASH_SOURCE[0]}"
    log_info "Marked script as installed=$status"
}

# Detect OS
detect_os() {
    local uname_out
    uname_out="$(uname -s)"
    case "$uname_out" in
        Darwin) OS="macos" ;;
        Linux)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ] || [ "$ID" = "kali" ]; then
                    OS="debian"
                    log_info "Detected: $PRETTY_NAME"
                else
                    log_error "Unsupported Linux distribution: $ID"
                    exit 1
                fi
            else
                log_error "Cannot determine Linux distribution"
                exit 1
            fi
            ;;
        *) log_error "Unsupported OS: $uname_out"; exit 1 ;;
    esac
}

# Main installation function
install() {
    log_info "Starting installation: $SCRIPT_NAME"
    log_info "Log file: $LOG_FILE"
    echo ""

    detect_os

    #######################################
    # INSTALLATION LOGIC
    #######################################

    case "$OS" in
        debian)
            check_root

            log_step "Step 1: Installing Nmap..."
            apt-get update && apt-get install -y nmap

            log_step "Step 2: Installing Zenmap..."
            apt-get install -y zenmap

            log_step "Step 3: Installing nmapUnleashed dependencies..."
            apt-get install -y xsltproc pipx

            log_step "Step 4: Installing nmapUnleashed via pipx..."
            pipx ensurepath
            pipx install "git+https://github.com/Sharkeonix/nmap-unleashed.git"
            ;;
        macos)
            if ! command -v brew &>/dev/null; then
                log_error "Homebrew is required. Install from https://brew.sh"
                exit 1
            fi

            log_step "Step 1: Installing Nmap..."
            brew install nmap

            log_step "Step 2: Installing Zenmap..."
            brew install --cask zenmap

            log_step "Step 3: Installing pipx and libxslt..."
            brew install pipx libxslt
            pipx ensurepath

            log_step "Step 4: Installing nmapUnleashed via pipx..."
            pipx install "git+https://github.com/Sharkeonix/nmap-unleashed.git"
            ;;
    esac

    #######################################
    # VERIFICATION
    #######################################

    echo ""
    log_step "Verifying installation..."

    command -v nmap &>/dev/null && log_success "nmap: $(nmap --version | head -1)" || log_warn "nmap not found"
    command -v zenmap &>/dev/null && log_success "zenmap: installed" || log_warn "zenmap not found in PATH (may be GUI-only)"
    command -v nu &>/dev/null && log_success "nmapUnleashed: installed" || log_warn "nmapUnleashed (nu) not found - open a new terminal for PATH update"

    #######################################
    # END INSTALLATION LOGIC
    #######################################

    echo ""
    log_success "Installation complete: $SCRIPT_NAME"
    mark_installed true
}

# Uninstall function
uninstall() {
    log_info "Starting uninstallation: $SCRIPT_NAME"

    detect_os

    #######################################
    # UNINSTALLATION LOGIC
    #######################################

    case "$OS" in
        debian)
            check_root
            pipx uninstall nmap-unleashed 2>/dev/null || true
            apt-get remove -y zenmap nmap xsltproc && apt-get autoremove -y
            ;;
        macos)
            pipx uninstall nmap-unleashed 2>/dev/null || true
            brew uninstall --cask zenmap 2>/dev/null || true
            brew uninstall nmap 2>/dev/null || true
            ;;
    esac

    #######################################
    # END UNINSTALLATION LOGIC
    #######################################

    log_success "Uninstallation complete: $SCRIPT_NAME"
    mark_installed false
}

# Parse command line arguments
case "${1:-install}" in
    install)   install   ;;
    uninstall) uninstall ;;
    *)
        echo "Usage: $0 {install|uninstall}"
        exit 1
        ;;
esac
