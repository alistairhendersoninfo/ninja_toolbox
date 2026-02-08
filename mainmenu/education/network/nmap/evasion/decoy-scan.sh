#!/bin/bash
# ---
# name: "Decoy Scan"
# description: "Spoof multiple source IPs to mask the real scanner"
# version: "1.0.0"
# author: "NinjaMenu"
# type: tool
# root: true
# order: 20
# binary: "nmap"
# tags: "network, evasion, nmap, decoy"
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
    log_info "Nmap — Decoy Scan"
    log_info "Generates 5 random decoy IPs alongside your real scan (-D RND:5)."
    log_info "Makes it harder for the target to identify the true scanner. Requires root."
    echo ""

    read -rp "Enter target (IP, hostname, or CIDR range): " TARGET
    if [[ -z "$TARGET" ]]; then
        log_error "No target provided."
        exit 1
    fi

    log_step "Running: nmap -D RND:5 $TARGET"
    echo ""
    nmap -D RND:5 "$TARGET"

    echo ""
    log_success "Decoy scan complete."
}

run
