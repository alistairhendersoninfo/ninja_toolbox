#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="fluent-bit"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing Fluent Bit log processor"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root
    pkg_update

    log_step "1. Installing prerequisites..."
    pkg_install curl gnupg apt-transport-https

    log_step "2. Adding Fluent Bit GPG key..."
    curl -fsSL https://packages.fluentbit.io/fluentbit.key | gpg --dearmor -o /usr/share/keyrings/fluentbit.gpg

    log_step "3. Adding Fluent Bit apt repository..."
    # Detect the distribution codename
    local CODENAME
    CODENAME=$(lsb_release -cs 2>/dev/null || { grep VERSION_CODENAME /etc/os-release | cut -d= -f2; } || echo "bookworm")

    cat > /etc/apt/sources.list.d/fluent-bit.list <<EOF
deb [signed-by=/usr/share/keyrings/fluentbit.gpg] https://packages.fluentbit.io/debian/${CODENAME} ${CODENAME} main
EOF

    log_step "4. Updating package lists..."
    pkg_update

    log_step "5. Installing Fluent Bit..."
    pkg_install fluent-bit

    log_step "6. Enabling Fluent Bit service..."
    systemctl enable --now fluent-bit

    log_step "7. Verifying installation..."
    fluent-bit --version
    systemctl is-active fluent-bit

    echo ""
    log_success "Fluent Bit installed and running"
    log_info "Config: /etc/fluent-bit/fluent-bit.conf"
    log_info "Logs:   journalctl -u fluent-bit"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Fluent Bit"
    require_root

    systemctl stop fluent-bit 2>/dev/null || true
    systemctl disable fluent-bit 2>/dev/null || true
    pkg_remove fluent-bit
    rm -f /etc/apt/sources.list.d/fluent-bit.list
    rm -f /usr/share/keyrings/fluentbit.gpg
    apt-get autoremove -y 2>/dev/null || true

    log_success "Fluent Bit uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
