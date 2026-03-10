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
    log_info "Installing fd (fd-find)"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    pkg_update
    pkg_install fd-find

    # On Debian/Ubuntu the binary is named fdfind — create a symlink for convenience
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        log_step "Creating symlink: fdfind -> /usr/local/bin/fd"
        ln -sf "$(which fdfind)" /usr/local/bin/fd
    fi

    echo ""
    log_success "fd installed successfully"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling fd"
    require_root

    rm -f /usr/local/bin/fd
    pkg_remove fd-find

    log_success "fd uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
