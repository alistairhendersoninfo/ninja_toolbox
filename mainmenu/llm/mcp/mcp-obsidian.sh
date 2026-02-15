#!/bin/bash
# ---
# name: "MCP Obsidian Server"
# description: "MCP server for AI access to Obsidian vaults (read/write/search notes)"
# version: "1.0.0"
# author: "bitbonsai (Mauricio Wolff)"
# type: install
# root: false
# order: 10
# hidden: false
# installed: false
# check_command: "npx @mauricio.wolff/mcp-obsidian@latest --help"
# dependencies:
#   - node
# tags:
#   - llm
#   - mcp
#   - obsidian
#   - ai
#   - notes
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

CLAUDE_DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
CLAUDE_CODE_CONFIG="$HOME/.claude.json"

# ── macOS-only gate ──────────────────────────────────────────────────────────
check_macos() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_error "This script is macOS only. Linux binaries for Obsidian are not yet supported."
        exit 1
    fi
}

# ── Obsidian installed gate ──────────────────────────────────────────────────
check_obsidian() {
    if [[ ! -d "/Applications/Obsidian.app" ]]; then
        log_error "Obsidian is not installed. Install Obsidian first before setting up the MCP server."
        log_error "Download from: https://obsidian.md/download"
        exit 1
    fi
    log_info "Obsidian found at /Applications/Obsidian.app"
}

# ── Find Obsidian vaults ────────────────────────────────────────────────────
find_vaults() {
    local obsidian_config="$HOME/Library/Application Support/obsidian/obsidian.json"
    if [[ -f "$obsidian_config" ]]; then
        log_info "Obsidian config found — checking for known vaults..."
    fi

    # Search common locations for .obsidian directories (indicates a vault)
    local vaults=()
    while IFS= read -r vault_dir; do
        vaults+=("$(dirname "$vault_dir")")
    done < <({ find "$HOME/Documents" "$HOME/Desktop" "$HOME" -maxdepth 3 -name ".obsidian" -type d 2>/dev/null || true; } | head -10)

    if [[ ${#vaults[@]} -eq 0 ]]; then
        log_warn "No Obsidian vaults found automatically."
        echo ""
        read -rp "Enter the full path to your Obsidian vault: " vault_path
        if [[ -d "$vault_path" ]]; then
            echo "$vault_path"
        else
            log_error "Directory does not exist: $vault_path"
            exit 1
        fi
    elif [[ ${#vaults[@]} -eq 1 ]]; then
        log_info "Found vault: ${vaults[0]}"
        echo "${vaults[0]}"
    else
        log_info "Found ${#vaults[@]} vaults:"
        for i in "${!vaults[@]}"; do
            echo "  [$((i+1))] ${vaults[$i]}"
        done
        echo ""
        read -rp "Select vault number (1-${#vaults[@]}): " choice
        if [[ "$choice" -ge 1 && "$choice" -le ${#vaults[@]} ]]; then
            echo "${vaults[$((choice-1))]}"
        else
            log_error "Invalid selection"
            exit 1
        fi
    fi
}

# ── Configure Claude Desktop ────────────────────────────────────────────────
configure_claude_desktop() {
    local vault_path="$1"

    if [[ ! -d "$(dirname "$CLAUDE_DESKTOP_CONFIG")" ]]; then
        log_info "Claude Desktop config directory not found — skipping Claude Desktop config."
        return
    fi

    log_step "Configuring Claude Desktop MCP..."

    if [[ -f "$CLAUDE_DESKTOP_CONFIG" ]]; then
        # Backup existing config
        cp "$CLAUDE_DESKTOP_CONFIG" "${CLAUDE_DESKTOP_CONFIG}.bak"
        log_info "Backed up existing config to claude_desktop_config.json.bak"

        # Check if obsidian server already configured
        if grep -q '"obsidian"' "$CLAUDE_DESKTOP_CONFIG" 2>/dev/null; then
            log_warn "Obsidian MCP already configured in Claude Desktop — skipping."
            return
        fi

        # Add obsidian to existing mcpServers using python for safe JSON manipulation
        python3 -c "
import json, sys
with open('$CLAUDE_DESKTOP_CONFIG', 'r') as f:
    config = json.load(f)
config.setdefault('mcpServers', {})
config['mcpServers']['obsidian'] = {
    'command': 'npx',
    'args': ['@mauricio.wolff/mcp-obsidian@latest', '$vault_path']
}
with open('$CLAUDE_DESKTOP_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
"
    else
        # Create new config
        mkdir -p "$(dirname "$CLAUDE_DESKTOP_CONFIG")"
        cat > "$CLAUDE_DESKTOP_CONFIG" <<JSONEOF
{
  "mcpServers": {
    "obsidian": {
      "command": "npx",
      "args": ["@mauricio.wolff/mcp-obsidian@latest", "$vault_path"]
    }
  }
}
JSONEOF
    fi

    log_success "Claude Desktop configured with Obsidian MCP server"
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

# ── Install ──────────────────────────────────────────────────────────────────
install() {
    log_info "Installing MCP Obsidian Server..."
    log_info "Log file: $LOG_FILE"

    check_macos
    check_obsidian

    # Check Node.js
    if ! command -v node &>/dev/null; then
        log_error "Node.js is required but not installed."
        log_info "Install with: brew install node"
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

    # Pre-cache the package
    log_step "Downloading MCP Obsidian server package..."
    npx --yes @mauricio.wolff/mcp-obsidian@latest --help &>/dev/null || true

    # Find vault
    local vault_path
    vault_path="$(find_vaults)"
    log_info "Using vault: $vault_path"

    # Configure Claude Desktop and Claude Code
    configure_claude_desktop "$vault_path"
    configure_claude_code "$vault_path"

    echo ""
    log_success "MCP Obsidian Server installed and configured!"
    echo ""
    echo "  Vault:          $vault_path"
    echo "  Claude Desktop: Restart Claude Desktop to activate"
    echo "  Claude Code:    Run 'claude' — the obsidian MCP server will be available"
    echo ""
    echo "  Test with: npx @mauricio.wolff/mcp-obsidian@latest \"$vault_path\""
    echo ""

    mark_installed true
}

# ── Uninstall ────────────────────────────────────────────────────────────────
uninstall() {
    log_info "Removing MCP Obsidian Server configuration..."

    # Remove from Claude Desktop config
    if [[ -f "$CLAUDE_DESKTOP_CONFIG" ]]; then
        if grep -q '"obsidian"' "$CLAUDE_DESKTOP_CONFIG" 2>/dev/null; then
            python3 -c "
import json
with open('$CLAUDE_DESKTOP_CONFIG', 'r') as f:
    config = json.load(f)
if 'mcpServers' in config and 'obsidian' in config['mcpServers']:
    del config['mcpServers']['obsidian']
with open('$CLAUDE_DESKTOP_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
"
            log_success "Removed obsidian from Claude Desktop config"
        fi
    fi

    # Remove from Claude Code
    if command -v claude &>/dev/null; then
        claude mcp remove obsidian --scope user 2>/dev/null || true
        log_success "Removed obsidian from Claude Code config"
    fi

    # Clear npx cache for this package
    log_info "Clearing cached package..."
    npm cache clean --force 2>/dev/null || true

    log_success "MCP Obsidian Server removed"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
