#!/bin/bash

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
    log_info "Nmap-Unleashed — XML Export"
    log_info "Runs a scan and exports results in XML format."
    log_info "XML output can be parsed by other tools or imported into databases."
    echo ""

    read -rp "Enter target (IP, hostname, or CIDR range): " TARGET
    if [[ -z "$TARGET" ]]; then
        log_error "No target provided."
        exit 1
    fi

    log_step "Running: nu $TARGET --xml"
    echo ""
    nu "$TARGET" --xml

    echo ""
    log_success "XML export complete. Check the current directory for the output file."
}

run
