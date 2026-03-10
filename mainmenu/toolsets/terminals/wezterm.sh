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
    log_info "Installing WezTerm terminal emulator"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    log_step "Adding WezTerm APT repository..."
    curl -fsSL https://apt.fury.io/wez/gpg.key | gpg --dearmor -o /usr/share/keyrings/wezterm-fury.gpg 2>/dev/null || true
    echo "deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *" > /etc/apt/sources.list.d/wezterm.list

    log_step "Installing WezTerm..."
    pkg_update
    apt-get install -y wezterm

    echo ""
    log_success "WezTerm installed successfully"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling WezTerm"
    require_root

    apt-get remove -y wezterm 2>/dev/null || true
    apt-get autoremove -y 2>/dev/null || true

    rm -f /etc/apt/sources.list.d/wezterm.list
    rm -f /usr/share/keyrings/wezterm-fury.gpg

    log_success "WezTerm uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
