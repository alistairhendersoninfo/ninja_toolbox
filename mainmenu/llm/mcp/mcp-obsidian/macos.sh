#!/bin/bash
# macOS implementation — do NOT add YAML headers here (use meta.yaml)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

exec > >(tee -a "$LOG_FILE") 2>&1

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

# ── Configure Claude Desktop (macOS paths) ──────────────────────────────────
configure_claude_desktop() {
    local vault_path="$1"

    if [[ ! -d "$(dirname "$CLAUDE_DESKTOP_CONFIG")" ]]; then
        log_info "Claude Desktop config directory not found — skipping Claude Desktop config."
        return
    fi

    log_step "Configuring Claude Desktop MCP..."

    if [[ -f "$CLAUDE_DESKTOP_CONFIG" ]]; then
        cp "$CLAUDE_DESKTOP_CONFIG" "${CLAUDE_DESKTOP_CONFIG}.bak"
        log_info "Backed up existing config to claude_desktop_config.json.bak"

        if grep -q '"obsidian"' "$CLAUDE_DESKTOP_CONFIG" 2>/dev/null; then
            log_warn "Obsidian MCP already configured in Claude Desktop — skipping."
            return
        fi

        python3 -c "
import json
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

# ── Remove from Claude Desktop ──────────────────────────────────────────────
remove_claude_desktop() {
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
}

# ── Install ──────────────────────────────────────────────────────────────────
install() {
    log_info "Installing MCP Obsidian Server on macOS..."
    log_info "Log file: $LOG_FILE"

    check_obsidian
    check_node

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

    remove_claude_desktop
    remove_claude_code

    log_info "Clearing cached package..."
    npm cache clean --force 2>/dev/null || true

    log_success "MCP Obsidian Server removed"
    mark_installed false
}

ACTION="${1:-install}"

case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
