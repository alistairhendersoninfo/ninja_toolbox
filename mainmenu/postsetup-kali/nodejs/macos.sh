#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing Node.js 20 LTS..."
    log_info "Log file: $LOG_FILE"
    require_root

    # Check if already installed
    if check_nodejs_installed; then
        return 0
    fi

    log_step "Installing Node.js 20 via Homebrew..."
    brew install node@20
    brew link node@20 --overwrite 2>/dev/null || true

    show_versions
    mark_installed true
}

uninstall() {
    log_info "Removing Node.js..."
    require_root

    brew uninstall node@20 2>/dev/null || brew uninstall node 2>/dev/null || true

    log_success "Node.js removed"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
