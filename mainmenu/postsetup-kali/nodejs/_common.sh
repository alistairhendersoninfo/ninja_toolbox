#!/bin/bash
# Shared functions for nodejs — sourced by all OS scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
SCRIPT_NAME="nodejs"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOG_DIR"

# Check if Node.js 20 is already installed
check_nodejs_installed() {
    if command -v node &>/dev/null && node -v | grep -q "v20"; then
        log_info "Node.js 20 already installed: $(node -v)"
        mark_installed true
        return 0
    fi
    return 1
}

# Display Node.js and npm versions after successful install
show_versions() {
    log_success "Node.js installed successfully!"
    echo ""
    echo "Node.js version: $(node -v)"
    echo "npm version: $(npm -v)"
    echo ""
}
