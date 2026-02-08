#!/bin/bash
# ---
# name: "Broadcast Discovery"
# description: "Find hosts on the local network via broadcast protocols"
# version: "1.0.0"
# author: "NinjaMenu"
# type: tool
# root: true
# order: 40
# binary: "nmap"
# tags: "network, discovery, nmap, broadcast"
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
    log_info "Nmap — Broadcast Discovery"
    log_info "Discovers hosts on the local network using broadcast protocols."
    log_info "Uses --script broadcast-ping to find live hosts. Requires root."
    echo ""

    log_step "Running: nmap --script broadcast-ping"
    echo ""
    nmap --script broadcast-ping

    echo ""
    log_success "Broadcast discovery complete."
}

run
