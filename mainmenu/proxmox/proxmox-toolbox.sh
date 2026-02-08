#!/bin/bash
# ---
# name: "Proxmox Toolbox"
# description: "Quick first-time Proxmox VE/BS configuration with fail2ban, dependencies"
# version: "1.0.0"
# author: "Tontonjo"
# root: true
# order: 20
# hidden: false
# installed: false
# check_command: ""
# check_path: ""
# dependencies:
#   - wget
# tags:
#   - proxmox
#   - configuration
#   - security
#   - fail2ban
# ---

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"
require_linux "Proxmox Toolbox requires Linux (Proxmox VE)"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing Proxmox Toolbox..."
    log_info "Log file: $LOG_FILE"
    log_info "GitHub: https://github.com/Tontonjo/proxmox_toolbox"
    echo ""

    # Check if running on Proxmox
    if [[ ! -f /etc/pve/local/pve-ssl.pem ]] && [[ ! -d /etc/pve ]]; then
        log_warn "This doesn't appear to be a Proxmox VE host"
        log_warn "Proxmox Toolbox is designed for Proxmox servers, not guest VMs"
        echo ""
        read -p "Continue anyway? (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            log_info "Installation cancelled"
            exit 0
        fi
    fi

    log_step "Downloading and running Proxmox Toolbox..."

    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    wget -qO proxmox_toolbox.sh https://raw.githubusercontent.com/Tontonjo/proxmox_toolbox/main/proxmox_toolbox.sh
    bash proxmox_toolbox.sh

    cd ~
    rm -rf "$TEMP_DIR"

    echo ""
    log_success "Proxmox Toolbox completed!"
    echo ""
    echo "Features installed:"
    echo "  - ifupdown2, git, sudo, libsasl2-modules"
    echo "  - amd64-microcode (if selected)"
    echo "  - fail2ban with sshd protection (if selected)"
    echo ""

    mark_installed true
}

uninstall() {
    log_info "Proxmox Toolbox doesn't have a standard uninstall"
    log_info "Individual components would need to be removed manually"
    log_warn "This will only mark the script as not installed"

    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
