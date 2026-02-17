#!/bin/bash
# macOS implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing Cursor IDE..."
    log_info "Log file: $LOG_FILE"
    require_root

    # Check if already installed
    if command -v cursor &>/dev/null; then
        log_info "Cursor IDE already installed"
        mark_installed true
        return 0
    fi

    log_step "Installing Cursor via Homebrew..."
    brew install --cask cursor

    if command -v cursor &>/dev/null; then
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

    brew uninstall --cask cursor 2>/dev/null || true
    rm -rf ~/.config/Cursor
    rm -rf ~/.cursor

    log_success "Cursor IDE removed"
    mark_installed false
}

ACTION="${1:-install}"
case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
