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
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing Cursor IDE..."
    log_info "Log file: $LOG_FILE"
    require_root

    # Check if already installed
    if command -v cursor &>/dev/null || [[ -f /usr/bin/cursor ]] || [[ -f /opt/Cursor/cursor ]]; then
        log_info "Cursor IDE already installed"
        mark_installed true
        return 0
    fi

    case "$NT_OS" in
        linux)
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"

            if [[ "$NT_ARCH" == "x86_64" ]]; then
                DEB_URL="https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/2.4"
            elif [[ "$NT_ARCH" == "aarch64" ]]; then
                DEB_URL="https://api2.cursor.sh/updates/download/golden/linux-arm64-deb/cursor/2.4"
            else
                log_error "Unsupported architecture: $NT_ARCH"
                exit 1
            fi

            log_step "Downloading Cursor .deb package for $NT_ARCH..."
            curl -fsSL -o cursor.deb "$DEB_URL"

            log_step "Installing Cursor..."
            dpkg -i cursor.deb || apt-get install -f -y

            cd ~
            rm -rf "$TEMP_DIR"
            ;;
        macos)
            log_step "Installing Cursor via Homebrew..."
            brew install --cask cursor
            ;;
    esac

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
    require_root

    case "$NT_OS" in
        linux)
            apt-get remove -y cursor 2>/dev/null || dpkg -r cursor 2>/dev/null || true
            ;;
        macos)
            brew uninstall --cask cursor 2>/dev/null || true
            ;;
    esac
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
