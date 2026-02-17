#!/bin/bash
# macOS implementation — do NOT add YAML headers here (metadata lives in meta.yaml).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

ACTION="${1:-install}"

case "$ACTION" in
    install)
        log_info "Installing <tool> on macOS..."
        exec > >(tee -a "$LOG_FILE") 2>&1

        #######################################
        # YOUR macOS INSTALLATION LOGIC HERE
        #######################################

        # Example: brew install <pkg>

        #######################################
        # END INSTALLATION LOGIC
        #######################################

        mark_installed true
        log_success "<tool> installed successfully"
        ;;
    uninstall)
        log_info "Uninstalling <tool> from macOS..."
        exec > >(tee -a "$LOG_FILE") 2>&1

        #######################################
        # YOUR macOS UNINSTALLATION LOGIC HERE
        #######################################

        # Example: brew uninstall <pkg>

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
