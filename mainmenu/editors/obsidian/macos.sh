#!/bin/bash
# macOS implementation — do NOT add YAML headers here (metadata lives in meta.yaml).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

ACTION="${1:-install}"

case "$ACTION" in
    install)
        log_info "Installing Obsidian on macOS..."
        exec > >(tee -a "$LOG_FILE") 2>&1
        brew install --cask obsidian
        mark_installed true
        log_success "Obsidian installed successfully"
        ;;
    uninstall)
        log_info "Uninstalling Obsidian from macOS..."
        exec > >(tee -a "$LOG_FILE") 2>&1
        brew uninstall --cask obsidian 2>/dev/null || true
        mark_installed false
        log_success "Obsidian uninstalled successfully"
        ;;
    *)
        echo "Usage: $0 {install|uninstall}"
        exit 1
        ;;
esac
