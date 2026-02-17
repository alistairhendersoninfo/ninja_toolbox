#!/bin/bash
# Linux implementation — do NOT add YAML headers here (metadata lives in meta.yaml).
# Obsidian is not in apt repos; downloads .deb from GitHub releases.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

OBSIDIAN_DEB="/tmp/obsidian_latest.deb"

ACTION="${1:-install}"

case "$ACTION" in
    install)
        require_root
        log_info "Installing Obsidian on Linux..."
        exec > >(tee -a "$LOG_FILE") 2>&1

        # Get latest .deb URL from GitHub releases
        log_step "Fetching latest Obsidian release..."
        DEB_URL=$(curl -fsSL https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest \
            | grep "browser_download_url.*amd64\.deb" \
            | head -1 \
            | cut -d '"' -f 4)

        if [[ -z "$DEB_URL" ]]; then
            log_error "Could not find Obsidian .deb release"
            exit 1
        fi

        log_step "Downloading: $DEB_URL"
        curl -fsSL "$DEB_URL" -o "$OBSIDIAN_DEB"

        log_step "Installing .deb package..."
        dpkg -i "$OBSIDIAN_DEB" || apt-get install -f -y
        rm -f "$OBSIDIAN_DEB"

        mark_installed true
        log_success "Obsidian installed successfully"
        ;;
    uninstall)
        require_root
        log_info "Uninstalling Obsidian from Linux..."
        exec > >(tee -a "$LOG_FILE") 2>&1
        apt-get remove -y obsidian 2>/dev/null || true
        mark_installed false
        log_success "Obsidian uninstalled successfully"
        ;;
    *)
        echo "Usage: $0 {install|uninstall}"
        exit 1
        ;;
esac
