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
    log_info "Portainer — Start Container"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    if ! command -v docker &>/dev/null; then
        log_error "Docker is not installed."
        exit 1
    fi

    if ! docker info &>/dev/null; then
        log_error "Docker daemon is not running. Start Docker first."
        exit 1
    fi

    if docker ps --filter name=portainer --format '{{.Names}}' | grep -q portainer; then
        log_warn "Portainer is already running."
        docker ps --filter name=portainer --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        exit 0
    fi

    log_step "Starting Portainer container..."
    docker start portainer

    log_step "Verifying Portainer is up..."
    sleep 3
    if docker ps --filter name=portainer --format '{{.Names}}' | grep -q portainer; then
        log_success "Portainer is running."
        docker ps --filter name=portainer --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        log_error "Portainer did not start. Check: docker logs portainer"
        exit 1
    fi
}

uninstall() {
    log_info "This is a config/utility script - nothing to uninstall"
}

case "${1:-install}" in
    install)   install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
