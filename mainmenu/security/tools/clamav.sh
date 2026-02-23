#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="clamav"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing ClamAV antivirus"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root
    pkg_update

    log_step "1. Installing ClamAV and daemon..."
    pkg_install clamav clamav-daemon

    log_step "2. Stopping freshclam for manual update..."
    systemctl stop clamav-freshclam 2>/dev/null || true

    log_step "3. Updating virus definitions (this may take a moment)..."
    freshclam || {
        log_error "freshclam update failed — this can happen on first run if mirrors are busy"
        log_info "Definitions will update automatically once the service starts"
    }

    log_step "4. Starting ClamAV services..."
    systemctl enable --now clamav-freshclam
    systemctl enable --now clamav-daemon

    log_step "5. Verifying installation..."
    clamscan --version

    echo ""
    log_success "ClamAV installed and running"
    log_info "Scan files:  clamscan /path/to/file"
    log_info "Scan folder: clamscan -r /path/to/folder"
    log_info "Virus definitions update automatically via freshclam"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling ClamAV"
    require_root

    systemctl stop clamav-daemon 2>/dev/null || true
    systemctl stop clamav-freshclam 2>/dev/null || true
    systemctl disable clamav-daemon 2>/dev/null || true
    systemctl disable clamav-freshclam 2>/dev/null || true
    pkg_remove clamav clamav-daemon
    apt-get autoremove -y 2>/dev/null || true

    log_success "ClamAV uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
