#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

REQUIRED_BINARY="nmap"
if ! command -v "$REQUIRED_BINARY" &>/dev/null; then
    log_error "$REQUIRED_BINARY is not installed. Install it first from the menu."
    exit 1
fi

# Require root privileges for raw socket access
require_tool_root

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

run() {
    log_info "Nmap — Aggressive Scan"
    log_info "Enables OS detection, version detection, script scanning, and traceroute (-A)."
    log_info "Comprehensive but noisy — combines multiple nmap features. Requires root."
    echo ""

    read -rp "Enter target (IP, hostname, or CIDR range): " TARGET
    if [[ -z "$TARGET" ]]; then
        log_error "No target provided."
        exit 1
    fi

    log_step "Running: nmap -A $TARGET"
    echo ""
    nmap -A "$TARGET"

    echo ""
    log_success "Aggressive scan complete."
}

run
