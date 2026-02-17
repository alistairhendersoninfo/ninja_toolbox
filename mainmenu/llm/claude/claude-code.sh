#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"

if [ "$ACTION" = "install" ]; then
    log_info "Installing Claude Code CLI..."

    # Check if already installed
    if command -v claude &>/dev/null; then
        log_success "Claude Code already installed: $(claude --version 2>/dev/null)"
        exit 0
    fi

    # Download and run official installer
    curl -fsSL https://claude.ai/install.sh | bash

    # Update PATH for current session
    export PATH="$HOME/.local/bin:$PATH"

    if command -v claude &>/dev/null; then
        log_success "Claude Code installed successfully!"
        echo ""
        log_info "Quick Start:"
        echo "  claude           # Start interactive mode"
        echo "  claude \"query\"   # One-shot query"
        echo "  claude --help    # Show all options"
    else
        log_warn "Claude installed. You may need to restart your terminal or run:"
        echo 'export PATH="$HOME/.local/bin:$PATH"'
    fi
else
    log_info "Uninstalling Claude Code CLI..."
    rm -f "$HOME/.local/bin/claude"
    rm -rf "$HOME/.claude"
    log_success "Claude Code uninstalled."
fi
