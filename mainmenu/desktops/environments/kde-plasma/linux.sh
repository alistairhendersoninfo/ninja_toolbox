#!/bin/bash
# Linux implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
exec > >(tee -a "$LOG_FILE") 2>&1

require_linux "KDE Plasma requires Linux"

KDE_PACKAGES=(
    plasma-desktop
    kwin-wayland
    sddm
    dolphin
    konsole
    kde-spectacle
    systemsettings
    plasma-nm
    plasma-pa
)

install() {
    log_info "Installing KDE Plasma Desktop..."
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    log_step "Updating package list..."
    pkg_update

    log_step "Installing KDE Plasma packages (this may take a while)..."
    pkg_install "${KDE_PACKAGES[@]}"

    log_step "Enabling SDDM display manager..."
    systemctl enable sddm

    log_step "Setting graphical target as default..."
    systemctl set-default graphical.target

    echo ""
    log_success "KDE Plasma installed successfully!"
    echo ""
    echo "Post-install notes:"
    echo "  - SDDM has been enabled as the display manager"
    echo "  - Graphical target set as default boot target"
    echo "  - Reboot to start using KDE Plasma"
    echo ""

    mark_installed true
}

uninstall() {
    log_info "Removing KDE Plasma Desktop..."

    require_root

    log_step "Disabling SDDM..."
    systemctl disable sddm 2>/dev/null || true

    log_step "Removing KDE Plasma packages..."
    apt-get remove -y "${KDE_PACKAGES[@]}" 2>/dev/null || true
    apt-get autoremove -y

    echo ""
    log_success "KDE Plasma removed."
    log_info "You may want to install another display manager and desktop."

    mark_installed false
}

ACTION="${1:-install}"
case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
