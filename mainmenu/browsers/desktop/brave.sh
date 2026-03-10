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

KEYRING="/usr/share/keyrings/brave-browser-archive-keyring.gpg"
SOURCES_LIST="/etc/apt/sources.list.d/brave-browser-release.list"

install() {
    log_info "Installing Brave Browser"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    log_step "1. Adding Brave repository..."
    pkg_install curl gnupg apt-transport-https

    curl -fsSLo "$KEYRING" \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

    cat > "$SOURCES_LIST" <<EOF
deb [signed-by=${KEYRING}] https://brave-browser-apt-release.s3.brave.com/ stable main
EOF

    log_step "2. Installing brave-browser..."
    pkg_update
    pkg_install brave-browser

    log_step "3. Verifying installation..."
    brave-browser --version

    echo ""
    log_success "Brave Browser installed"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Brave Browser"
    require_root

    pkg_remove brave-browser
    rm -f "$SOURCES_LIST"
    rm -f "$KEYRING"
    apt-get autoremove -y 2>/dev/null || true

    log_success "Brave Browser uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
