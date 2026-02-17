#!/bin/bash
# Common functions and setup for nmap-tools-bundle
# Do NOT add YAML headers here (use meta.yaml)

# Determine script location and menu root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"

# Source platform detection
source "$MENU_ROOT/.lib/platform.sh"

# Setup logging
LOG_DIR="$MENU_ROOT/.docs/logs"
SCRIPT_NAME="nmap-tools-bundle"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"

#######################################
# SHARED VERIFICATION FUNCTION
#######################################

verify_installation() {
    echo ""
    log_step "Verifying installation..."

    command -v nmap &>/dev/null && log_success "nmap: $(nmap --version | head -1)" || log_warn "nmap not found"
    command -v zenmap &>/dev/null && log_success "zenmap: installed" || log_warn "zenmap not found in PATH (may be GUI-only)"
    command -v nu &>/dev/null && log_success "nmapUnleashed: installed" || log_warn "nmapUnleashed (nu) not found - open a new terminal for PATH update"
}
