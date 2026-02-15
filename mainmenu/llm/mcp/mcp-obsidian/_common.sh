#!/bin/bash
# Shared functions for MCP Obsidian — sourced by all OS scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
SCRIPT_NAME="mcp-obsidian"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$LOG_DIR"

CLAUDE_DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

# ── Check Node.js v18+ ──────────────────────────────────────────────────────
check_node() {
    if ! command -v node &>/dev/null; then
        log_error "Node.js is required but not installed."
        log_info "Install with your package manager (e.g., brew install node)"
        exit 1
    fi

    local node_version
    node_version="$(node --version | sed 's/v//')"
    local node_major="${node_version%%.*}"
    if [[ "$node_major" -lt 18 ]]; then
        log_error "Node.js v18+ required. Current: v${node_version}"
        exit 1
    fi
    log_info "Node.js v${node_version} found"
}

# ── Configure Claude Code ───────────────────────────────────────────────────
configure_claude_code() {
    local vault_path="$1"

    log_step "Configuring Claude Code MCP..."

    if command -v claude &>/dev/null; then
        claude mcp add obsidian --scope user npx @mauricio.wolff/mcp-obsidian@latest "$vault_path"
        log_success "Claude Code configured with Obsidian MCP server"
    else
        log_warn "Claude Code CLI not found — skipping Claude Code config."
        log_info "To add manually later: claude mcp add obsidian --scope user npx @mauricio.wolff/mcp-obsidian@latest \"$vault_path\""
    fi
}

# ── Remove from Claude Code ─────────────────────────────────────────────────
remove_claude_code() {
    if command -v claude &>/dev/null; then
        claude mcp remove obsidian --scope user 2>/dev/null || true
        log_success "Removed obsidian from Claude Code config"
    fi
}
