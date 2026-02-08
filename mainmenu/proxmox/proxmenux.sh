#!/bin/bash
# ---
# name: "ProxMenux"
# description: "Interactive menu for Proxmox VE management with scripts and commands"
# version: "1.0.0"
# author: "MacRimi"
# root: true
# order: 10
# hidden: false
# installed: false
# check_command: "proxmenux --help"
# check_path: "/usr/local/bin/proxmenux"
# dependencies:
#   - wget
#   - curl
# tags:
#   - proxmox
#   - management
#   - menu
# ---

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"
require_linux "ProxMenux requires Linux (Proxmox VE)"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing ProxMenux..."
    log_info "Log file: $LOG_FILE"
    log_info "GitHub: https://github.com/MacRimi/ProxMenux"
    echo ""

    # Check if running on Proxmox
    if [[ ! -f /etc/pve/local/pve-ssl.pem ]] && [[ ! -d /etc/pve ]]; then
        log_warn "This doesn't appear to be a Proxmox VE host"
        log_warn "ProxMenux is designed for Proxmox servers, not guest VMs"
        echo ""
        read -p "Continue anyway? (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            log_info "Installation cancelled"
            exit 0
        fi
    fi

    log_step "Running ProxMenux installer..."
    bash -c "$(wget -qLO - https://raw.githubusercontent.com/MacRimi/ProxMenux/main/install_proxmenux.sh)"

    echo ""
    log_success "ProxMenux installed!"
    echo ""
    echo "To launch ProxMenux, run:"
    echo "  proxmenux"
    echo ""
    echo "Or use the command menu in Proxmox web interface"
    echo ""

    mark_installed true
}

uninstall() {
    log_info "Removing ProxMenux..."

    # Remove the script and config
    rm -f /usr/local/bin/proxmenux
    rm -rf /root/.proxmenux
    rm -rf /var/lib/proxmenux

    log_success "ProxMenux removed"

    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
