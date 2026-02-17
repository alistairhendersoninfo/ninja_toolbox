#!/bin/bash
# Linux implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing Cursor IDE..."
    log_info "Log file: $LOG_FILE"
    require_root

    # Check if already installed
    if command -v cursor &>/dev/null || [[ -f /usr/bin/cursor ]] || [[ -f /opt/Cursor/cursor ]]; then
        log_info "Cursor IDE already installed"
        mark_installed true
        return 0
    fi

    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    if [[ "$NT_ARCH" == "x86_64" ]]; then
        DEB_URL="https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/2.4"
    elif [[ "$NT_ARCH" == "aarch64" ]]; then
        DEB_URL="https://api2.cursor.sh/updates/download/golden/linux-arm64-deb/cursor/2.4"
    else
        log_error "Unsupported architecture: $NT_ARCH"
        exit 1
    fi

    log_step "Downloading Cursor .deb package for $NT_ARCH..."
    curl -fsSL -o cursor.deb "$DEB_URL"

    log_step "Installing Cursor..."
    dpkg -i cursor.deb || apt-get install -f -y

    cd ~
    rm -rf "$TEMP_DIR"

    if command -v cursor &>/dev/null || [[ -f /opt/Cursor/cursor ]]; then
        log_success "Cursor IDE installed successfully!"
        echo ""
        echo "Run 'cursor' to launch Cursor IDE"
        echo ""
        mark_installed true
    else
        log_error "Cursor installation may have failed"
        exit 1
    fi
}

uninstall() {
    log_info "Removing Cursor IDE..."
    require_root

    apt-get remove -y cursor 2>/dev/null || dpkg -r cursor 2>/dev/null || true
    rm -rf ~/.config/Cursor
    rm -rf ~/.cursor

    log_success "Cursor IDE removed"
    mark_installed false
}

ACTION="${1:-install}"
case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
