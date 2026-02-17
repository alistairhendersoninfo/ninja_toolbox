#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

check_nodejs() {
    if ! command -v node &>/dev/null; then
        log_error "Node.js is not installed. Please install Node.js first."
        exit 1
    fi
    if ! command -v npm &>/dev/null; then
        log_error "npm is not installed. Please install npm first."
        exit 1
    fi
}

install() {
    log_info "Installing OpenAI Codex CLI..."
    log_info "Log file: $LOG_FILE"

    check_nodejs

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
