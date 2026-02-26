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

install() {
    log_info "Nginx — Stop Service"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    if ! command -v nginx &>/dev/null; then
        log_error "Nginx is not installed."
        exit 1
    fi

    log_step "Stopping nginx service..."
    systemctl stop nginx

    echo ""
    log_success "Nginx stopped."
}

uninstall() {
    log_info "This is a config/utility script - nothing to uninstall"
}

case "${1:-install}" in
    install)   install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
