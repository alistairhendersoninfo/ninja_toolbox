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
    log_info "Installing bat"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    pkg_update
    pkg_install bat

    # On Debian/Ubuntu the binary is named batcat — create a symlink for convenience
    if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        log_step "Creating symlink: batcat -> /usr/local/bin/bat"
        ln -sf "$(which batcat)" /usr/local/bin/bat
    fi

    echo ""
    log_success "bat installed successfully"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling bat"
    require_root

    rm -f /usr/local/bin/bat
    pkg_remove bat

    log_success "bat uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
