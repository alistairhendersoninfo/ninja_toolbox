#!/bin/bash
# macOS implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing Google Antigravity IDE..."
    log_info "Log file: $LOG_FILE"
    require_root

    # Check if already installed
    if command -v antigravity &>/dev/null; then
        log_info "Antigravity already installed"
        mark_installed true
        return 0
    fi

    log_step "Installing Antigravity via Homebrew..."
    brew install --cask antigravity

    if command -v antigravity &>/dev/null; then
        log_success "Google Antigravity IDE installed successfully!"
        echo ""
        echo "Run 'antigravity' to launch"
        echo "Or 'antigravity /path/to/project' to open a project"
        echo ""
        mark_installed true
    else
        log_error "Antigravity installation failed"
        exit 1
    fi
}

uninstall() {
    log_info "Removing Google Antigravity IDE..."
    require_root

    brew uninstall --cask antigravity 2>/dev/null || true
    rm -rf ~/.config/antigravity
    rm -rf ~/.antigravity

    log_success "Google Antigravity IDE removed"
    mark_installed false
}

ACTION="${1:-install}"
case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
