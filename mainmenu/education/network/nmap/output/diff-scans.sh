#!/bin/bash
# ---
# name: "Diff Scans"
# description: "Run two scans and compare differences with ndiff"
# version: "1.0.0"
# author: "NinjaMenu"
# type: tool
# root: false
# order: 30
# binary: "nmap"
# tags: "network, output, nmap, diff, ndiff"
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
    log_info "Nmap — Diff Scans"
    log_info "Runs two scans of the same target and compares them with ndiff."
    log_info "Useful for detecting changes — new hosts, ports, or services."
    echo ""

    if ! command -v ndiff &>/dev/null; then
        log_error "ndiff is not installed. It usually comes with nmap."
        exit 1
    fi

    read -rp "Enter target (IP, hostname, or CIDR range): " TARGET
    if [[ -z "$TARGET" ]]; then
        log_error "No target provided."
        exit 1
    fi

    SCAN1="/tmp/nmap_diff_scan1_$$.xml"
    SCAN2="/tmp/nmap_diff_scan2_$$.xml"

    log_step "Running first scan..."
    nmap -oX "$SCAN1" "$TARGET"
    echo ""

    log_info "First scan saved. Press Enter to run the second scan."
    read -r

    log_step "Running second scan..."
    nmap -oX "$SCAN2" "$TARGET"
    echo ""

    log_step "Comparing scans with ndiff..."
    echo ""
    ndiff "$SCAN1" "$SCAN2"

    rm -f "$SCAN1" "$SCAN2"

    echo ""
    log_success "Diff scan complete."
}

run
