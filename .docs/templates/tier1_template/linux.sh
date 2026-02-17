#!/bin/bash
# Generic Linux implementation — do NOT add YAML headers here (metadata lives in meta.yaml).
# This covers Debian, Ubuntu, and Kali unless you create distro-specific scripts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

ACTION="${1:-install}"

case "$ACTION" in
    install)
        require_root
        log_info "Installing <tool> on Linux..."
        exec > >(tee -a "$LOG_FILE") 2>&1

        #######################################
        # YOUR Linux INSTALLATION LOGIC HERE
        #######################################

        # Example: apt-get install -y <pkg>

        #######################################
        # END INSTALLATION LOGIC
        #######################################

        mark_installed true
        log_success "<tool> installed successfully"
        ;;
    uninstall)
        require_root
        log_info "Uninstalling <tool> from Linux..."
        exec > >(tee -a "$LOG_FILE") 2>&1

        #######################################
        # YOUR Linux UNINSTALLATION LOGIC HERE
        #######################################

        # Example: apt-get remove -y <pkg>

        #######################################
        # END UNINSTALLATION LOGIC
        #######################################

        mark_installed false
        log_success "<tool> uninstalled successfully"
        ;;
    *)
        echo "Usage: $0 {install|uninstall}"
        exit 1
        ;;
esac
