#!/bin/bash
# ---
# name: "Script Display Name"
# description: "Brief description of what this script does"
# version: "1.0.0"
# author: "Your Name"
# type: install
# root: false
# order: 50
# hidden: false
# installed: false
# check_command: "myapp --version"
# check_path: "/usr/bin/myapp:~/.local/bin/myapp"
# uninstall: ""
# dependencies:
#   - curl
#   - git
# tags:
#   - category
# ---
#
# type options:
#   install - Shows Install/Uninstall actions (default)
#   config  - Shows Run action only (for utilities/config scripts)

#######################################
# SCRIPT TEMPLATE
# Copy this file and modify for new installers
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

# Check for required commands
check_dependencies() {
    local deps=("$@")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Install with: sudo apt install ${missing[*]}"
        exit 1
    fi
}

# Update the installed status in this script's YAML header
mark_installed() {
    local status="${1:-true}"
    sed -i "s/^# installed: .*/# installed: $status/" "${BASH_SOURCE[0]}"
    log_info "Marked script as installed=$status"
}

# Main installation function
install() {
    log_info "Starting installation: $SCRIPT_NAME"
    log_info "Log file: $LOG_FILE"
    echo ""

    # Uncomment if root is required
    # check_root

    # Check dependencies
    # check_dependencies curl git wget

    #######################################
    # YOUR INSTALLATION LOGIC HERE
    #######################################

    log_step "Step 1: Doing something..."
    # Your code here

    log_step "Step 2: Doing something else..."
    # Your code here

    #######################################
    # END INSTALLATION LOGIC
    #######################################

    echo ""
    log_success "Installation complete: $SCRIPT_NAME"
    mark_installed true
}

# Uninstall function (optional)
uninstall() {
    log_info "Starting uninstallation: $SCRIPT_NAME"

    #######################################
    # YOUR UNINSTALLATION LOGIC HERE
    #######################################

    # Your uninstall code here

    #######################################
    # END UNINSTALLATION LOGIC
    #######################################

    log_success "Uninstallation complete: $SCRIPT_NAME"
    mark_installed false
}

# Parse command line arguments
case "${1:-install}" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Usage: $0 {install|uninstall}"
        exit 1
        ;;
esac
