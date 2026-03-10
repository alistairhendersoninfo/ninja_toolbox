#!/bin/bash
# Metadata lives in the companion .meta.yaml file (NOT inline).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"

source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

KEYRING="/usr/share/keyrings/google-chrome.gpg"
SOURCES_LIST="/etc/apt/sources.list.d/google-chrome.list"

install() {
    log_info "Installing Google Chrome"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    log_step "1. Checking architecture..."
    ARCH="$(dpkg --print-architecture)"
    if [[ "$ARCH" != "amd64" ]]; then
        log_error "Google Chrome only supports amd64. Detected: $ARCH"
        exit 1
    fi

    log_step "2. Adding Google Chrome repository..."
    pkg_install curl gnupg apt-transport-https

    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | \
        gpg --dearmor -o "$KEYRING" 2>/dev/null || true

    cat > "$SOURCES_LIST" <<EOF
deb [arch=amd64 signed-by=${KEYRING}] https://dl.google.com/linux/chrome/deb/ stable main
EOF

    log_step "3. Installing google-chrome-stable..."
    pkg_update
    pkg_install google-chrome-stable

    log_step "4. Verifying installation..."
    google-chrome --version

    echo ""
    log_success "Google Chrome installed"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Google Chrome"
    require_root

    pkg_remove google-chrome-stable
    rm -f "$SOURCES_LIST"
    rm -f "$KEYRING"
    apt-get autoremove -y 2>/dev/null || true

    log_success "Google Chrome uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
