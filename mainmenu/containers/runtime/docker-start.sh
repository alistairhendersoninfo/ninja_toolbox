#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Docker — Start Service"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    log_step "Starting Docker service..."
    systemctl start docker

    log_step "Waiting for Docker daemon to be ready..."
    timeout 30 bash -c 'until docker info &>/dev/null; do sleep 1; done'

    echo ""
    log_success "Docker service started."
    log_info "Containers with --restart=always or --restart=unless-stopped will auto-start."
    echo ""
    log_info "--- Running containers ---"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

uninstall() {
    log_info "This is a config/utility script - nothing to uninstall"
}

case "${1:-install}" in
    install)   install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
