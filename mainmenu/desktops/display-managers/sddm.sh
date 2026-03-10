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

SDDM_PACKAGES=(
    sddm
    sddm-theme-breeze
)

install() {
    log_info "Installing SDDM Display Manager..."
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    log_step "Updating package list..."
    pkg_update

    log_step "Installing SDDM and Breeze theme..."
    pkg_install "${SDDM_PACKAGES[@]}"

    log_step "Enabling SDDM service..."
    systemctl enable sddm

    echo ""
    log_success "SDDM installed successfully!"
    echo ""
    echo "Post-install notes:"
    echo "  - SDDM has been enabled as the display manager"
    echo "  - The Breeze theme is included"
    echo "  - Reboot to use SDDM as your login screen"
    echo ""

    mark_installed true
}

uninstall() {
    log_info "Removing SDDM Display Manager..."

    require_root

    log_step "Disabling SDDM..."
    systemctl disable sddm 2>/dev/null || true
    systemctl stop sddm 2>/dev/null || true

    log_step "Removing SDDM packages..."
    apt-get remove -y "${SDDM_PACKAGES[@]}" 2>/dev/null || true
    apt-get autoremove -y

    echo ""
    log_success "SDDM removed."
    log_info "You may need to enable another display manager (e.g., lightdm, gdm3)."

    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
