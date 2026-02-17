#!/bin/bash
# macOS implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
exec > >(tee -a "$LOG_FILE") 2>&1

#######################################
# MACOS INSTALLATION
#######################################

install() {
    log_info "Starting installation: $SCRIPT_NAME (macOS)"
    log_info "Log file: $LOG_FILE"
    echo ""
    require_root

    log_step "Step 1: Installing Nmap..."
    brew install nmap

    log_step "Step 2: Installing Zenmap..."
    brew install --cask zenmap

    log_step "Step 3: Installing pipx and libxslt..."
    brew install pipx libxslt
    pipx ensurepath

    log_step "Step 4: Installing nmapUnleashed via pipx..."
    pipx install "git+https://github.com/Sharkeonix/nmap-unleashed.git"

    verify_installation

    echo ""
    log_success "Installation complete: $SCRIPT_NAME"
    mark_installed true
}

#######################################
# MACOS UNINSTALLATION
#######################################

uninstall() {
    log_info "Starting uninstallation: $SCRIPT_NAME (macOS)"
    require_root

    log_step "Uninstalling nmapUnleashed..."
    pipx uninstall nmap-unleashed 2>/dev/null || true

    log_step "Uninstalling Zenmap..."
    brew uninstall --cask zenmap 2>/dev/null || true

    log_step "Uninstalling nmap and dependencies..."
    brew uninstall nmap pipx libxslt 2>/dev/null || true

    log_success "Uninstallation complete: $SCRIPT_NAME"
    mark_installed false
}

#######################################
# MAIN
#######################################

ACTION="${1:-install}"
case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
