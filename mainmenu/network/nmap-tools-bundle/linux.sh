#!/bin/bash
# Linux implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
exec > >(tee -a "$LOG_FILE") 2>&1

#######################################
# LINUX INSTALLATION
#######################################

install() {
    log_info "Starting installation: $SCRIPT_NAME (Linux)"
    log_info "Log file: $LOG_FILE"
    echo ""
    require_root

    log_step "Step 1: Installing Nmap..."
    apt-get update && apt-get install -y nmap

    log_step "Step 2: Installing Zenmap..."
    apt-get install -y zenmap

    log_step "Step 3: Installing nmapUnleashed dependencies..."
    apt-get install -y xsltproc pipx

    log_step "Step 4: Installing nmapUnleashed via pipx..."
    pipx ensurepath
    pipx install "git+https://github.com/Sharkeonix/nmap-unleashed.git"

    verify_installation

    echo ""
    log_success "Installation complete: $SCRIPT_NAME"
    mark_installed true
}

#######################################
# LINUX UNINSTALLATION
#######################################

uninstall() {
    log_info "Starting uninstallation: $SCRIPT_NAME (Linux)"
    require_root

    log_step "Uninstalling nmapUnleashed..."
    pipx uninstall nmap-unleashed 2>/dev/null || true

    log_step "Uninstalling packages..."
    apt-get remove -y zenmap nmap xsltproc pipx && apt-get autoremove -y

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
