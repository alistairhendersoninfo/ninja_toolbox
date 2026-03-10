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

KEYRING="/usr/share/keyrings/opera-browser.gpg"
SOURCES_LIST="/etc/apt/sources.list.d/opera-stable.list"

install() {
    log_info "Installing Opera Browser"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    log_step "1. Adding Opera repository..."
    pkg_install curl gnupg apt-transport-https

    curl -fsSL https://deb.opera.com/archive.key | \
        gpg --dearmor -o "$KEYRING" 2>/dev/null || true

    cat > "$SOURCES_LIST" <<EOF
deb [signed-by=${KEYRING}] https://deb.opera.com/opera-stable/ stable non-free
EOF

    log_step "2. Installing opera-stable..."
    pkg_update
    pkg_install opera-stable

    log_step "3. Verifying installation..."
    opera --version

    echo ""
    log_success "Opera Browser installed"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Opera Browser"
    require_root

    pkg_remove opera-stable
    rm -f "$SOURCES_LIST"
    rm -f "$KEYRING"
    apt-get autoremove -y 2>/dev/null || true

    log_success "Opera Browser uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
