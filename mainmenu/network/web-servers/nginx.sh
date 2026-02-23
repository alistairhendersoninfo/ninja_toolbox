#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="nginx"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing Nginx"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root
    pkg_update

    log_step "Installing nginx..."
    pkg_install nginx

    log_step "Enabling nginx service..."
    systemctl enable --now nginx

    log_step "Verifying installation..."
    nginx -v 2>&1
    systemctl is-active nginx

    echo ""
    log_success "Nginx installed and running"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Nginx"
    require_root

    systemctl stop nginx 2>/dev/null || true
    systemctl disable nginx 2>/dev/null || true
    pkg_remove nginx
    apt-get autoremove -y 2>/dev/null || true

    log_success "Nginx uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
