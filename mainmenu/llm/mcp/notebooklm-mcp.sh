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

check_python() {
    if ! command -v python3 &>/dev/null; then
        log_error "Python 3 is not installed. Please install Python 3.9+ first."
        exit 1
    fi
    local py_version
    py_version=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    local py_major py_minor
    py_major=$(echo "$py_version" | cut -d. -f1)
    py_minor=$(echo "$py_version" | cut -d. -f2)
    if [[ "$py_major" -lt 3 ]] || { [[ "$py_major" -eq 3 ]] && [[ "$py_minor" -lt 9 ]]; }; then
        log_error "Python 3.9+ required, found Python $py_version"
        exit 1
    fi
    log_info "Python $py_version detected"
}

install() {
    log_info "Installing NotebookLM MCP Server..."
    log_info "Log file: $LOG_FILE"

    check_python

    if command -v notebooklm-mcp &>/dev/null; then
        log_info "NotebookLM MCP Server already installed"
        mark_installed true
        return 0
    fi

    if command -v uv &>/dev/null; then
        log_step "Installing notebooklm-mcp-cli via uv..."
        uv tool install notebooklm-mcp-cli
    elif command -v pipx &>/dev/null; then
        log_step "Installing notebooklm-mcp-cli via pipx..."
        pipx install notebooklm-mcp-cli
    else
        log_step "Installing notebooklm-mcp-cli via pip..."
        pip install --user notebooklm-mcp-cli
    fi

    if command -v notebooklm-mcp &>/dev/null; then
        log_success "NotebookLM MCP Server installed successfully!"
        echo ""
        echo "Configure for your AI tool:"
        echo "  nlm setup add claude-code   # Claude Code"
        echo "  nlm setup add cursor        # Cursor"
        echo "  nlm setup add gemini        # Gemini CLI"
        echo ""
        echo "Authenticate first if not already done:"
        echo "  nlm login"
        echo ""
        mark_installed true
    else
        log_error "NotebookLM MCP Server installation failed"
        exit 1
    fi
}

uninstall() {
    log_info "Removing NotebookLM MCP Server..."

    if command -v uv &>/dev/null; then
        uv tool uninstall notebooklm-mcp-cli 2>/dev/null || true
    elif command -v pipx &>/dev/null; then
        pipx uninstall notebooklm-mcp-cli 2>/dev/null || true
    else
        pip uninstall -y notebooklm-mcp-cli 2>/dev/null || true
    fi

    log_success "NotebookLM MCP Server removed"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
