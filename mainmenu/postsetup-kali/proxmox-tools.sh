#!/bin/bash
# ---
# name: "Proxmox Guest Agent"
# description: "Installs QEMU guest agent for Proxmox VM integration"
# version: "1.0.0"
# author: "System"
# root: true
# order: 20
# hidden: false
# installed: false
# check_command: ""
# check_path: "/usr/sbin/qemu-ga"
# dependencies:
#   - apt
# tags:
#   - proxmox
#   - virtualization
#   - system
# ---

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()    { echo -e "${CYAN}[STEP]${NC} $1"; }

mark_installed() {
    local status="${1:-true}"
    sed -i "s/^# installed: .*/# installed: $status/" "${BASH_SOURCE[0]}"
}

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

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
