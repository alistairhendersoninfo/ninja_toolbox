#!/bin/bash
# ---
# name: "Config Script Name"
# description: "Brief description of what this config/utility does"
# version: "1.0.0"
# author: "Your Name"
# type: config
# root: false
# order: 50
# hidden: false
# installed: false
# check_command: ""
# check_path: ""
# dependencies: []
# tags:
#   - config
#   - utility
# ---

#######################################
# CONFIG/UTILITY TEMPLATE
# Use this for scripts that don't install software
# but perform configuration, reset, or utility tasks
#######################################

set -euo pipefail

# Determine script location and menu root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"

# Source cross-platform library (provides logging, nt_sed_i, etc.)
source "$MENU_ROOT/.lib/platform.sh"

# Setup logging
LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Main function (called when user selects "Run")
install() {
    log_info "Running: $SCRIPT_NAME"
    log_info "Log file: $LOG_FILE"
    echo ""

    #######################################
    # YOUR CONFIG/UTILITY LOGIC HERE
    #######################################

    log_step "Step 1: Doing something..."
    # Your code here

    log_step "Step 2: Doing something else..."
    # Your code here

    #######################################
    # END LOGIC
    #######################################

    echo ""
    log_success "Complete: $SCRIPT_NAME"
}

# Uninstall is typically not used for config scripts
uninstall() {
    log_info "This is a config/utility script - nothing to uninstall"
}

# Parse command line arguments
case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
