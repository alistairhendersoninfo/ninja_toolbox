#!/bin/bash
# ---
# name: "Claude CLI"
# description: "Anthropic's official CLI for Claude AI"
# version: "1.0.0"
# author: "Anthropic"
# root: false
# order: 10
# hidden: false
# installed: false
# check_command: "claude --version"
# check_path: "~/.local/bin/claude"
# dependencies:
#   - curl
# tags:
#   - llm
#   - cli
#   - anthropic
#   - ai
# ---

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

    # Ensure PATH is updated
    export PATH="$HOME/.local/bin:$PATH"

    if command -v claude &>/dev/null; then
        log_success "Claude CLI installed successfully!"
        echo ""
        echo "Run 'claude' to start using it"
        echo ""
        mark_installed true
    else
        log_warn "Claude CLI may need PATH update. Add to your shell config:"
        echo 'export PATH="$HOME/.local/bin:$PATH"'
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
