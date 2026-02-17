#!/bin/bash
# Linux implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
exec > >(tee -a "$LOG_FILE") 2>&1

require_linux "Proxmox Guest Agent requires Linux"

install() {
    log_info "Installing Proxmox Guest Agent..."
    log_info "Log file: $LOG_FILE"

    log_step "Updating package list..."
    apt-get update -qq

    log_step "Installing qemu-guest-agent..."
    apt-get install -y qemu-guest-agent

    log_step "Enabling service..."
    systemctl enable qemu-guest-agent 2>/dev/null || true
    systemctl start qemu-guest-agent 2>/dev/null || log_warn "Service couldn't start - enable Guest Agent in Proxmox VM settings first"

    echo ""
    log_success "Proxmox Guest Agent installed!"
    echo ""
    echo "Next steps:"
    echo "1. In Proxmox web UI, select your VM"
    echo "2. Go to Options > QEMU Guest Agent"
    echo "3. Enable it"
    echo "4. Restart the VM"
    echo ""

    mark_installed true
}

uninstall() {
    log_info "Removing Proxmox Guest Agent..."

    systemctl stop qemu-guest-agent 2>/dev/null || true
    systemctl disable qemu-guest-agent 2>/dev/null || true
    apt-get remove -y qemu-guest-agent
    apt-get autoremove -y

    log_success "Proxmox Guest Agent removed"

    mark_installed false
}

ACTION="${1:-install}"
case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
