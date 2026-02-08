#!/bin/bash
# ---
# name: "Idle Scan"
# description: "Use a zombie host to scan without revealing your IP"
# version: "1.0.0"
# author: "NinjaMenu"
# type: tool
# root: true
# order: 30
# binary: "nmap"
# tags: "network, evasion, nmap, idle, zombie"
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
    log_info "Nmap — Idle Scan"
    log_info "Uses an idle 'zombie' host to scan the target without revealing your IP (-sI)."
    log_info "The zombie's IP ID sequence is used to infer open ports. Requires root."
    echo ""

    read -rp "Enter zombie host (IP of an idle host): " ZOMBIE
    if [[ -z "$ZOMBIE" ]]; then
        log_error "No zombie host provided."
        exit 1
    fi

    read -rp "Enter target (IP, hostname, or CIDR range): " TARGET
    if [[ -z "$TARGET" ]]; then
        log_error "No target provided."
        exit 1
    fi

    log_step "Running: nmap -sI $ZOMBIE $TARGET"
    echo ""
    nmap -sI "$ZOMBIE" "$TARGET"

    echo ""
    log_success "Idle scan complete."
}

run
