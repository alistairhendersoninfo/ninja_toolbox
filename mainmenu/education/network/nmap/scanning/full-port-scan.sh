#!/bin/bash
# ---
# name: "Full Port Scan"
# description: "Scan all 65535 TCP ports"
# version: "1.0.0"
# author: "NinjaMenu"
# type: tool
# root: false
# order: 30
# binary: "nmap"
# tags: "network, scanning, nmap, comprehensive"
# ---

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
    log_info "Nmap — Full Port Scan"
    log_info "Scans all 65535 TCP ports (-p-)."
    log_info "This is thorough but slow — expect several minutes per host."
    echo ""

    read -rp "Enter target (IP, hostname, or CIDR range): " TARGET
    if [[ -z "$TARGET" ]]; then
        log_error "No target provided."
        exit 1
    fi

    log_step "Running: nmap -p- $TARGET"
    echo ""
    nmap -p- "$TARGET"

    echo ""
    log_success "Full port scan complete."
}

run
