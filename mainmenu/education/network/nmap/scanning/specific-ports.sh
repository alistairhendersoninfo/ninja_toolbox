#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

REQUIRED_BINARY="nmap"
if ! command -v "$REQUIRED_BINARY" &>/dev/null; then
    log_error "$REQUIRED_BINARY is not installed. Install it first from the menu."
    exit 1
fi

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

run() {
    log_info "Nmap — Specific Ports"
    log_info "Scan only the ports you specify (-p)."
    log_info "Examples: 80,443 or 1-1024 or 22,80,443,8080"
    echo ""

    read -rp "Enter target (IP, hostname, or CIDR range): " TARGET
    if [[ -z "$TARGET" ]]; then
        log_error "No target provided."
        exit 1
    fi

    read -rp "Enter ports (e.g. 80,443 or 1-1024): " PORTS
    if [[ -z "$PORTS" ]]; then
        log_error "No ports provided."
        exit 1
    fi

    log_step "Running: nmap -p $PORTS $TARGET"
    echo ""
    nmap -p "$PORTS" "$TARGET"

    echo ""
    log_success "Specific ports scan complete."
}

run
