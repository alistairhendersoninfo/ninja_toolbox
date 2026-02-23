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

ensure_path() {
    local path_line='export PATH="$HOME/.local/bin:$PATH"'
    local shell_rc

    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$(basename "${SHELL:-}")" == "zsh" ]]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi

    if [[ -f "$shell_rc" ]] && ! grep -qF '.local/bin' "$shell_rc"; then
        log_step "Adding ~/.local/bin to PATH in $shell_rc..."
        echo "$path_line" >> "$shell_rc"
    fi

    export PATH="$HOME/.local/bin:$PATH"
}

install() {
    log_info "Installing Claude CLI..."
    log_info "Log file: $LOG_FILE"

    # Check if already installed
    if command -v claude &>/dev/null; then
        log_info "Claude CLI already installed: $(claude --version 2>/dev/null || echo 'version unknown')"
        mark_installed true
        return 0
    fi

    log_step "Downloading and running Claude installer..."
    curl -fsSL https://claude.ai/install.sh | bash

    # Ensure PATH is updated in current session and persisted to shell config
    ensure_path

    if command -v claude &>/dev/null; then
        log_success "Claude CLI installed successfully!"
        echo ""
        echo "Run 'claude' to start using it"
        echo ""
        mark_installed true
    else
        log_warn "Claude CLI installed but not found in PATH."
        if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$(basename "${SHELL:-}")" == "zsh" ]]; then
            log_warn "Restart your shell or run: source ~/.zshrc"
        else
            log_warn "Restart your shell or run: source ~/.bashrc"
        fi
        mark_installed true
    fi
}

uninstall() {
    log_info "Removing Claude CLI..."

    # Remove the binary
    rm -f "$HOME/.local/bin/claude"
    rm -rf "$HOME/.claude"

    log_success "Claude CLI removed"

    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
