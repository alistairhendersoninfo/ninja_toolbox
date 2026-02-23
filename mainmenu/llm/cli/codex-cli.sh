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
    log_info "Installing OpenAI Codex CLI..."
    log_info "Log file: $LOG_FILE"

    install_nodejs

    # Check if already installed
    if command -v codex &>/dev/null; then
        log_info "Codex CLI already installed"
        mark_installed true
        return 0
    fi

    log_step "Installing @openai/codex via npm..."
    npm install -g @openai/codex

    if command -v codex &>/dev/null; then
        log_success "Codex CLI installed successfully!"
        echo ""
        echo "Run 'codex' to start using it"
        echo "You'll need to set your OPENAI_API_KEY environment variable"
        echo ""
        mark_installed true
    else
        log_error "Codex CLI installation failed"
        exit 1
    fi
}

uninstall() {
    log_info "Removing OpenAI Codex CLI..."

    npm uninstall -g @openai/codex || true

    log_success "Codex CLI removed"

    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
