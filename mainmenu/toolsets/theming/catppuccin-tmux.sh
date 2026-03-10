#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Running: Catppuccin Mocha theme for tmux"
    log_info "Log file: $LOG_FILE"
    echo ""

    if ! command -v tmux &>/dev/null; then
        log_error "tmux is not installed. Install it first from Dev Tools."
        exit 1
    fi

    TPM_DIR="$HOME/.tmux/plugins/tpm"
    TMUX_CONF="$HOME/.tmux.conf"

    # Install TPM if not present
    if [[ ! -d "$TPM_DIR" ]]; then
        log_step "Installing tmux plugin manager (TPM)..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    else
        log_info "TPM already installed"
    fi

    # Add catppuccin plugin to tmux.conf
    log_step "Configuring Catppuccin tmux plugin..."
    touch "$TMUX_CONF"

    if ! grep -q "catppuccin/tmux" "$TMUX_CONF" 2>/dev/null; then
        cat >> "$TMUX_CONF" <<'TMUXEOF'

# Catppuccin Mocha theme
set -g @plugin 'catppuccin/tmux'
set -g @catppuccin_flavour 'mocha'

# TPM (keep this line at the very bottom of tmux.conf)
set -g @plugin 'tmux-plugins/tpm'
run '~/.tmux/plugins/tpm/tpm'
TMUXEOF
        log_info "Catppuccin plugin added to $TMUX_CONF"
    else
        log_info "Catppuccin tmux plugin already configured"
    fi

    # Ensure TPM run line exists at end
    if ! grep -q "run.*tpm/tpm" "$TMUX_CONF" 2>/dev/null; then
        echo "" >> "$TMUX_CONF"
        echo "run '~/.tmux/plugins/tpm/tpm'" >> "$TMUX_CONF"
    fi

    echo ""
    log_success "Catppuccin tmux theme configured"
    log_info "Press prefix + I inside tmux to install the plugin via TPM"
}

uninstall() {
    log_info "This is a config/utility script - nothing to uninstall"
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
