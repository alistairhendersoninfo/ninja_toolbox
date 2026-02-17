#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Fixing ZSH configuration..."
    log_info "Log file: $LOG_FILE"

    ZSHRC="$HOME/.zshrc"

    if [[ ! -f "$ZSHRC" ]]; then
        log_warn ".zshrc not found at $ZSHRC"
        exit 1
    fi

    # Backup original
    cp "$ZSHRC" "$ZSHRC.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Created backup of .zshrc"

    # Comment out problematic undercover lines
    if grep -q ": undercover &&" "$ZSHRC"; then
        nt_sed_i 's/^: undercover && /# : undercover \&\& /' "$ZSHRC"
        log_success "Commented out undercover lines in .zshrc"
    else
        log_info "No undercover lines found (may already be fixed)"
    fi

    log_success "ZSH configuration fixed!"
    log_info "Run 'source ~/.zshrc' or restart your terminal"

    mark_installed true
}

uninstall() {
    log_info "Restoring original ZSH configuration..."

    ZSHRC="$HOME/.zshrc"

    # Find most recent backup
    BACKUP=$(ls -t "$ZSHRC.backup."* 2>/dev/null | head -1)

    if [[ -n "$BACKUP" && -f "$BACKUP" ]]; then
        cp "$BACKUP" "$ZSHRC"
        log_success "Restored from backup: $BACKUP"
    else
        # Just uncomment the lines
        nt_sed_i 's/^# : undercover \&\& /: undercover \&\& /' "$ZSHRC"
        log_success "Uncommented undercover lines"
    fi

    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
