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

    log_step "Adding NodeSource repository..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -

    log_step "Installing nodejs..."
    apt-get install -y nodejs

    # Verify npm is available
    if ! command -v npm &>/dev/null; then
        log_step "Installing npm..."
        apt-get install -y npm
    fi

    show_versions
    mark_installed true
}

uninstall() {
    log_info "Removing Node.js..."
    require_root

    apt-get remove -y nodejs npm || true
    apt-get autoremove -y
    rm -f /etc/apt/sources.list.d/nodesource.list

    log_success "Node.js removed"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
