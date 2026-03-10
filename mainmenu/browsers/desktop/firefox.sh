#!/bin/bash
# Metadata lives in the companion .meta.yaml file (NOT inline).

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
    log_info "Installing Firefox ESR"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    log_step "1. Installing firefox-esr from default repositories..."
    pkg_update
    pkg_install firefox-esr

    log_step "2. Verifying installation..."
    firefox-esr --version

    echo ""
    log_success "Firefox ESR installed"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Firefox ESR"
    require_root

    pkg_remove firefox-esr
    apt-get autoremove -y 2>/dev/null || true

    log_success "Firefox ESR uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
