#!/bin/bash
# Metadata lives in net-tools.meta.yaml

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
    log_info "Installing net-tools (netstat, ifconfig, route, arp)..."
    log_info "Log file: $LOG_FILE"

    require_root

    log_step "Installing net-tools package..."
    pkg_update
    pkg_install net-tools

    if command -v netstat &>/dev/null; then
        log_success "net-tools installed successfully!"
        echo ""
        echo "Provides: netstat, ifconfig, route, arp, netplugd"
        echo ""
        echo "Usage: netstat -tuln          (list open ports)"
        echo "       netstat -rn            (routing table)"
        echo "       ifconfig               (network interfaces)"
        echo ""
        mark_installed true
    else
        log_error "net-tools installation failed"
        exit 1
    fi
}

uninstall() {
    log_info "Removing net-tools..."

    require_root
    pkg_remove net-tools

    log_success "net-tools removed"
    mark_installed false
}

case "${1:-install}" in
    install)   install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
