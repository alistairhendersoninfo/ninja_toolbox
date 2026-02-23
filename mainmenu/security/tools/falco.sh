#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="falco"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

FALCO_GPG_KEY="https://falco.org/repo/falcosecurity-packages.asc"
FALCO_REPO="https://download.falco.org/packages/deb"

install() {
    log_info "Installing Falco runtime security"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root
    pkg_update

    log_step "1. Adding Falco GPG key..."
    curl -fsSL "$FALCO_GPG_KEY" | gpg --dearmor -o /usr/share/keyrings/falcosecurity.gpg

    log_step "2. Adding Falco apt repository..."
    cat > /etc/apt/sources.list.d/falcosecurity.list <<EOF
deb [signed-by=/usr/share/keyrings/falcosecurity.gpg] ${FALCO_REPO} stable main
EOF

    log_step "3. Updating package lists..."
    pkg_update

    log_step "4. Installing Falco..."
    pkg_install falco

    log_step "5. Enabling Falco service..."
    systemctl enable --now falco

    log_step "6. Verifying installation..."
    falco --version
    systemctl is-active falco

    echo ""
    log_success "Falco installed and running"
    log_info "Falco monitors syscalls for suspicious activity in real time"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Falco"
    require_root

    systemctl stop falco 2>/dev/null || true
    systemctl disable falco 2>/dev/null || true
    pkg_remove falco
    rm -f /etc/apt/sources.list.d/falcosecurity.list
    rm -f /usr/share/keyrings/falcosecurity.gpg
    apt-get autoremove -y 2>/dev/null || true

    log_success "Falco uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
