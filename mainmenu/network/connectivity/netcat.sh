#!/bin/bash
# Metadata lives in netcat.meta.yaml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"

source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing netcat (nc)..."
    log_info "Log file: $LOG_FILE"

    require_root

    log_step "Installing netcat-openbsd..."
    pkg_update
    pkg_install netcat-openbsd

    if command -v nc &>/dev/null; then
        log_success "netcat (nc) installed successfully!"
        echo ""
        echo "Usage: nc <host> <port>        (connect)"
        echo "       nc -l <port>            (listen)"
        echo "       nc -zv <host> 20-30     (port scan)"
        echo ""
        mark_installed true
    else
        log_error "netcat installation failed"
        exit 1
    fi
}

uninstall() {
    log_info "Removing netcat (nc)..."

    require_root
    pkg_remove netcat-openbsd

    log_success "netcat removed"
    mark_installed false
}

case "${1:-install}" in
    install)   install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
