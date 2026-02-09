#!/bin/bash
# ---
# name: "XML Output"
# description: "Save scan results as XML for tool parsing"
# version: "1.0.0"
# author: "NinjaMenu"
# type: tool
# root: false
# order: 20
# binary: "nmap"
# tags: "network, output, nmap, xml"
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
    log_info "Nmap — XML Output"
    log_info "Saves scan results in XML format (-oX)."
    log_info "XML output can be imported into tools like Metasploit or parsed with scripts."
    echo ""

    read -rp "Enter target (IP, hostname, or CIDR range): " TARGET
    if [[ -z "$TARGET" ]]; then
        log_error "No target provided."
        exit 1
    fi

    read -rp "Enter output filename (e.g. scan.xml): " OUTFILE
    if [[ -z "$OUTFILE" ]]; then
        log_error "No filename provided."
        exit 1
    fi

    log_step "Running: nmap -oX $OUTFILE $TARGET"
    echo ""
    nmap -oX "$OUTFILE" "$TARGET"

    echo ""
    log_success "XML output complete."
}

run
