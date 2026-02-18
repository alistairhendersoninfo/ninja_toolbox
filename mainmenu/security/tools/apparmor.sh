#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="apparmor"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing AppArmor with enforced profiles"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root
    pkg_update

    log_step "1. Installing AppArmor packages..."
    pkg_install apparmor apparmor-utils apparmor-profiles apparmor-profiles-extra

    log_step "2. Enabling AppArmor service..."
    systemctl enable --now apparmor

    log_step "3. Enforcing all available profiles..."
    # Enforce each profile, skipping any that fail (some may not be valid for this system)
    for profile in /etc/apparmor.d/*; do
        # Skip directories and non-profile files
        [[ -d "$profile" ]] && continue
        [[ "$(basename "$profile")" == *.* ]] && continue
        aa-enforce "$profile" 2>/dev/null || {
            log_info "Skipped profile: $(basename "$profile")"
        }
    done

    log_step "4. Verifying AppArmor status..."
    aa-status

    echo ""
    log_success "AppArmor installed with profiles enforced"
    log_info "Check status:  aa-status"
    log_info "Set complain:  aa-complain /etc/apparmor.d/<profile>"
    log_info "Set enforce:   aa-enforce /etc/apparmor.d/<profile>"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling AppArmor"
    require_root

    # Set all profiles to complain mode before removing
    for profile in /etc/apparmor.d/*; do
        [[ -d "$profile" ]] && continue
        [[ "$(basename "$profile")" == *.* ]] && continue
        aa-complain "$profile" 2>/dev/null || true
    done

    systemctl stop apparmor 2>/dev/null || true
    systemctl disable apparmor 2>/dev/null || true
    pkg_remove apparmor apparmor-utils apparmor-profiles apparmor-profiles-extra
    apt-get autoremove -y 2>/dev/null || true

    log_success "AppArmor uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
