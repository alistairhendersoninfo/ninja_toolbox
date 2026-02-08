#!/bin/bash
# ---
# name: "Slow Scan"
# description: "Paranoid/sneaky timing to evade IDS detection"
# version: "1.0.0"
# author: "NinjaMenu"
# type: tool
# root: true
# order: 40
# binary: "nmap"
# tags: "network, evasion, nmap, timing, ids"
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
    log_info "Nmap — Slow Scan"
    log_info "Uses 'sneaky' timing template to avoid triggering IDS alerts (-T1)."
    log_info "Very slow — waits 15 seconds between probes. Good for stealth."
    echo ""

    read -rp "Enter target (IP, hostname, or CIDR range): " TARGET
    if [[ -z "$TARGET" ]]; then
        log_error "No target provided."
        exit 1
    fi

    log_step "Running: nmap -T1 $TARGET"
    echo ""
    nmap -T1 "$TARGET"

    echo ""
    log_success "Slow scan complete."
}

run
