#!/bin/bash
# Linux implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
exec > >(tee -a "$LOG_FILE") 2>&1

require_linux "Cinnamon requires Linux"

CINNAMON_PACKAGES=(
    cinnamon
    cinnamon-core
    nemo
    cinnamon-settings-daemon
    cinnamon-session
    xapps-common
    lightdm
)

install() {
    log_info "Installing Cinnamon Desktop..."
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    log_step "Updating package list..."
    pkg_update

    log_step "Installing Cinnamon packages (this may take a while)..."
    pkg_install "${CINNAMON_PACKAGES[@]}"

    log_step "Enabling LightDM display manager..."
    systemctl enable lightdm

    log_step "Setting graphical target as default..."
    systemctl set-default graphical.target

    echo ""
    log_success "Cinnamon Desktop installed successfully!"
    echo ""
    echo "Post-install notes:"
    echo "  - LightDM has been enabled as the display manager"
    echo "  - Graphical target set as default boot target"
    echo "  - Reboot to start using Cinnamon"
    echo ""

    mark_installed true
}

uninstall() {
    log_info "Removing Cinnamon Desktop..."

    require_root

    log_step "Disabling LightDM..."
    systemctl disable lightdm 2>/dev/null || true

    log_step "Removing Cinnamon packages..."
    apt-get remove -y "${CINNAMON_PACKAGES[@]}" 2>/dev/null || true
    apt-get autoremove -y

    echo ""
    log_success "Cinnamon removed."
    log_info "You may want to install another display manager and desktop."

    mark_installed false
}

ACTION="${1:-install}"
case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
