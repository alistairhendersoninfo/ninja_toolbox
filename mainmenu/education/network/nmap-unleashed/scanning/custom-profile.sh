#!/bin/bash
# ---
# name: "Custom Profile"
# description: "Run a scan with user-selected nmap-unleashed options"
# version: "1.0.0"
# author: "NinjaMenu"
# type: tool
# root: false
# order: 30
# binary: "nu"
# tags: "network, scanning, nmap-unleashed, custom"
# ---

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

REQUIRED_BINARY="nu"
if ! command -v "$REQUIRED_BINARY" &>/dev/null; then
    log_error "$REQUIRED_BINARY is not installed. Install nmap-unleashed first from the menu."
    exit 1
fi

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

run() {
    log_info "Nmap-Unleashed — Custom Profile"
    log_info "Run nmap-unleashed with your own options."
    log_info "Type 'nu --help' for available flags."
    echo ""

    read -rp "Enter target (IP, hostname, or CIDR range): " TARGET
    if [[ -z "$TARGET" ]]; then
        log_error "No target provided."
        exit 1
    fi

    read -rp "Enter additional nu options (or press Enter for defaults): " OPTIONS

    if [[ -z "$OPTIONS" ]]; then
        log_step "Running: nu $TARGET"
        echo ""
        nu "$TARGET"
    else
        log_step "Running: nu $TARGET $OPTIONS"
        echo ""
        # shellcheck disable=SC2086
        nu "$TARGET" $OPTIONS
    fi

    echo ""
    log_success "Custom profile scan complete."
}

run
