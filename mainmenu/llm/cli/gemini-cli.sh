#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install_nodejs() {
    if command -v node &>/dev/null && command -v npm &>/dev/null; then
        log_info "Node.js $(node --version) and npm already available"
        return 0
    fi

    log_step "Installing Node.js and npm..."

    if [[ "$NT_OS" == "linux" ]]; then
        require_root
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
        # npm is included with NodeSource package; install separately if missing
        if ! command -v npm &>/dev/null; then
            apt-get install -y npm
        fi
    elif [[ "$NT_OS" == "macos" ]]; then
        brew install node@20
    fi

    if ! command -v node &>/dev/null || ! command -v npm &>/dev/null; then
        log_error "Failed to install Node.js/npm"
        exit 1
    fi
    log_success "Node.js $(node --version) installed"
}

install() {
    log_info "Installing Gemini CLI..."
    log_info "Log file: $LOG_FILE"

    install_nodejs

    # Check if already installed
    if command -v gemini &>/dev/null; then
        log_info "Gemini CLI already installed"
        mark_installed true
        return 0
    fi

    log_step "Installing @google/gemini-cli via npm..."
    npm install -g @google/gemini-cli

    if command -v gemini &>/dev/null; then
        log_success "Gemini CLI installed successfully!"
        echo ""
        echo "Run 'gemini' to start using it"
        echo ""
        mark_installed true
    else
        log_error "Gemini CLI installation failed"
        exit 1
    fi
}

uninstall() {
    log_info "Removing Gemini CLI..."

    npm uninstall -g @google/gemini-cli || true

    log_success "Gemini CLI removed"

    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
