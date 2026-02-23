#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="security-bundle"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

TOOLS=(falco auditd clamav apparmor fluent-bit)

install() {
    log_info "Installing Security Bundle (all security tools)"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    local FAILED=()
    local SUCCEEDED=()

    for tool in "${TOOLS[@]}"; do
        echo ""
        log_step "===== Installing $tool ====="
        if bash "$SCRIPT_DIR/${tool}.sh" install; then
            SUCCEEDED+=("$tool")
        else
            log_error "Failed to install $tool — continuing with remaining tools"
            FAILED+=("$tool")
        fi
    done

    echo ""
    echo "============================================"
    log_success "Security Bundle installation complete"
    echo ""
    log_info "Succeeded: ${SUCCEEDED[*]:-none}"
    if [[ ${#FAILED[@]} -gt 0 ]]; then
        log_error "Failed: ${FAILED[*]}"
    fi
    echo "============================================"

    mark_installed true
}

uninstall() {
    log_info "Uninstalling Security Bundle (all security tools)"
    require_root

    for tool in "${TOOLS[@]}"; do
        echo ""
        log_step "===== Uninstalling $tool ====="
        bash "$SCRIPT_DIR/${tool}.sh" uninstall || {
            log_error "Failed to uninstall $tool — continuing"
        }
    done

    echo ""
    log_success "Security Bundle uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
