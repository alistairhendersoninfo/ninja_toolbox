#!/bin/bash
# ---
# name: "Node.js 20 LTS"
# description: "Installs Node.js 20.x LTS and npm package manager"
# version: "1.0.0"
# author: "System"
# root: true
# order: 5
# hidden: false
# installed: false
# check_command: "node --version"
# check_path: "/usr/bin/node"
# dependencies:
#   - curl
# tags:
#   - development
#   - nodejs
#   - npm
#   - javascript
# ---

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()    { echo -e "${CYAN}[STEP]${NC} $1"; }

mark_installed() {
    local status="${1:-true}"
    sed -i "s/^# installed: .*/# installed: $status/" "${BASH_SOURCE[0]}"
}

install() {
    log_info "Installing Node.js 20 LTS..."
    log_info "Log file: $LOG_FILE"

    # Check if Node.js 20 is already installed
    if command -v node &>/dev/null && node -v | grep -q "v20"; then
        log_info "Node.js 20 already installed: $(node -v)"
        mark_installed true
        return 0
    fi

    log_step "Adding NodeSource repository..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -

    log_step "Installing nodejs..."
    apt-get install -y nodejs

    # Verify npm is available
    if ! command -v npm &>/dev/null; then
        log_step "Installing npm..."
        apt-get install -y npm
    fi

    log_success "Node.js installed successfully!"
    echo ""
    echo "Node.js version: $(node -v)"
    echo "npm version: $(npm -v)"
    echo ""

    mark_installed true
}

uninstall() {
    log_info "Removing Node.js..."

    apt-get remove -y nodejs npm || true
    apt-get autoremove -y

    # Remove NodeSource repo
    rm -f /etc/apt/sources.list.d/nodesource.list

    log_success "Node.js removed"

    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
