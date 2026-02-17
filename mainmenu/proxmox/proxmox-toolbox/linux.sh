#!/bin/bash
# Linux implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
exec > >(tee -a "$LOG_FILE") 2>&1

require_linux "Proxmox Toolbox requires Linux (Proxmox VE)"

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

ACTION="${1:-install}"
case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
