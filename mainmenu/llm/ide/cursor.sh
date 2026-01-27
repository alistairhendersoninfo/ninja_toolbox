#!/bin/bash
# ---
# name: "Cursor IDE"
# description: "AI-powered code editor built on VS Code"
# version: "1.0.0"
# author: "Cursor"
# root: true
# order: 10
# hidden: false
# installed: false
# check_command: "cursor --version"
# check_path: "/usr/bin/cursor:/opt/Cursor/cursor"
# dependencies:
#   - curl
#   - dpkg
# tags:
#   - ide
#   - editor
#   - ai
#   - cursor
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
    log_info "Installing Cursor IDE..."
    log_info "Log file: $LOG_FILE"

    # Check if already installed
    if command -v cursor &>/dev/null || [[ -f /usr/bin/cursor ]] || [[ -f /opt/Cursor/cursor ]]; then
        log_info "Cursor IDE already installed"
        mark_installed true
        return 0
    fi

    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # Detect architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        DEB_URL="https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/2.4"
    elif [[ "$ARCH" == "aarch64" ]]; then
        DEB_URL="https://api2.cursor.sh/updates/download/golden/linux-arm64-deb/cursor/2.4"
    else
        log_error "Unsupported architecture: $ARCH"
        exit 1
    fi

    log_step "Downloading Cursor .deb package for $ARCH..."
    curl -fsSL -o cursor.deb "$DEB_URL"

    log_step "Installing Cursor..."
    dpkg -i cursor.deb || apt-get install -f -y

    cd ~
    rm -rf "$TEMP_DIR"

    if command -v cursor &>/dev/null || [[ -f /opt/Cursor/cursor ]]; then
        log_success "Cursor IDE installed successfully!"
        echo ""
        echo "Run 'cursor' to launch Cursor IDE"
        echo ""
        mark_installed true
    else
        log_error "Cursor installation may have failed"
        exit 1
    fi
}

uninstall() {
    log_info "Removing Cursor IDE..."

    apt-get remove -y cursor 2>/dev/null || dpkg -r cursor 2>/dev/null || true
    rm -rf ~/.config/Cursor
    rm -rf ~/.cursor

    log_success "Cursor IDE removed"

    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
