#!/bin/bash
# Metadata lives in the companion .meta.yaml file (NOT inline).
# Copy script_template.meta.yaml alongside this script and fill in the fields.
# See: .docs/technical_manuals/os-modular-architecture.md for full reference.

#######################################
# SCRIPT TEMPLATE
# Copy this file and modify for new installers
#######################################

set -euo pipefail

# Determine script location and menu root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"

# Source cross-platform library (provides logging, pkg_install, require_root, etc.)
source "$MENU_ROOT/.lib/platform.sh"

# Setup logging
LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Main installation function
install() {
    log_info "Starting installation: $SCRIPT_NAME"
    log_info "Log file: $LOG_FILE"
    echo ""

    # Uncomment if root/admin is required
    # require_root

    # Check dependencies
    # check_dependencies curl git wget

    #######################################
    # YOUR INSTALLATION LOGIC HERE
    #######################################

    # Simple package install (cross-platform):
    #   pkg_update
    #   pkg_install mypackage

    # If your tool needs different install steps per OS:
    #   case "$NT_OS" in
    #       linux)
    #           apt-get install -y mypackage
    #           ;;
    #       macos)
    #           brew install mypackage
    #           ;;
    #   esac

    log_step "Step 1: Doing something..."
    # Your code here

    log_step "Step 2: Doing something else..."
    # Your code here

    #######################################
    # END INSTALLATION LOGIC
    #######################################

    echo ""
    log_success "Installation complete: $SCRIPT_NAME"
    mark_installed true
}

# Uninstall function (optional)
uninstall() {
    log_info "Starting uninstallation: $SCRIPT_NAME"

    #######################################
    # YOUR UNINSTALLATION LOGIC HERE
    #######################################

    # Simple package removal (cross-platform):
    #   pkg_remove mypackage

    #######################################
    # END UNINSTALLATION LOGIC
    #######################################

    log_success "Uninstallation complete: $SCRIPT_NAME"
    mark_installed false
}

# Parse command line arguments
case "${1:-install}" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Usage: $0 {install|uninstall}"
        exit 1
        ;;
esac
