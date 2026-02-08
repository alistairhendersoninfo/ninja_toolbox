#!/bin/bash
# ---
# name: "Traceroute"
# description: "Map the network path to a target host"
# version: "1.0.0"
# author: "NinjaMenu"
# type: tool
# root: true
# order: 40
# binary: "nmap"
# tags: "network, footprinting, nmap, traceroute"
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
    log_info "Nmap — Traceroute"
    log_info "Maps the network path (hops) between you and the target (--traceroute)."
    log_info "Shows each router hop. Requires root privileges."
    echo ""

    read -rp "Enter target (IP, hostname, or CIDR range): " TARGET
    if [[ -z "$TARGET" ]]; then
        log_error "No target provided."
        exit 1
    fi

    log_step "Running: nmap --traceroute $TARGET"
    echo ""
    nmap --traceroute "$TARGET"

    echo ""
    log_success "Traceroute complete."
}

run
