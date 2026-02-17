#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"
require_linux "PVE Helper Scripts require Linux (Proxmox VE)"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing PVE Helper Scripts..."
    log_info "Log file: $LOG_FILE"
    log_info "GitHub: https://github.com/community-scripts/ProxmoxVE"
    log_info "Website: https://community-scripts.github.io/ProxmoxVE/"
    echo ""

    # Check if running on Proxmox
    if [[ ! -f /etc/pve/local/pve-ssl.pem ]] && [[ ! -d /etc/pve ]]; then
        log_warn "This doesn't appear to be a Proxmox VE host"
        log_warn "PVE Helper Scripts are designed for Proxmox servers"
        echo ""
        read -p "Continue anyway? (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            log_info "Installation cancelled"
            exit 0
        fi
    fi

    log_step "Installing PVE Scripts local menu..."
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/pve-scripts-local.sh)"

    echo ""
    log_success "PVE Helper Scripts installed!"
    echo ""
    echo "Access scripts from:"
    echo "  - Proxmox web interface menu"
    echo "  - https://community-scripts.github.io/ProxmoxVE/"
    echo ""
    echo "Popular scripts include:"
    echo "  - LXC container creation (Docker, Home Assistant, etc.)"
    echo "  - VM templates"
    echo "  - Backup solutions"
    echo "  - Monitoring tools"
    echo ""

    mark_installed true
}

uninstall() {
    log_info "Removing PVE Helper Scripts..."

    # Remove local scripts if they exist
    rm -rf /usr/local/share/pve-scripts 2>/dev/null || true
    rm -f /usr/local/bin/pve-scripts 2>/dev/null || true

    log_success "PVE Helper Scripts removed"

    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
