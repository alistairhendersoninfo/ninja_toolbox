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
    log_info "Running: Catppuccin Mocha theme for Neovim"
    log_info "Log file: $LOG_FILE"
    echo ""

    if ! command -v nvim &>/dev/null; then
        log_error "Neovim is not installed. Install it first from Dev Tools."
        exit 1
    fi

    NVIM_CONFIG="$HOME/.config/nvim"
    PLUGIN_DIR="$NVIM_CONFIG/lua/plugins"
    mkdir -p "$PLUGIN_DIR"

    # Detect plugin manager
    if [[ -d "$HOME/.local/share/nvim/lazy" ]] || [[ -f "$NVIM_CONFIG/lua/config/lazy.lua" ]] || grep -rq "lazy" "$NVIM_CONFIG" 2>/dev/null; then
        log_step "Detected lazy.nvim — writing plugin spec..."
        cat > "$PLUGIN_DIR/catppuccin.lua" <<'LUAEOF'
return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",
      transparent_background = false,
      integrations = {
        treesitter = true,
        native_lsp = { enabled = true },
        cmp = true,
        gitsigns = true,
        telescope = { enabled = true },
        mason = true,
        which_key = true,
      },
    })
    vim.cmd.colorscheme("catppuccin")
  end,
}
LUAEOF
    elif [[ -f "$NVIM_CONFIG/lua/plugins.lua" ]] && grep -q "packer" "$NVIM_CONFIG/lua/plugins.lua" 2>/dev/null; then
        log_step "Detected packer.nvim — writing plugin spec..."
        cat > "$PLUGIN_DIR/catppuccin.lua" <<'LUAEOF'
-- Add to your packer config:
-- use { "catppuccin/nvim", as = "catppuccin" }
require("catppuccin").setup({ flavour = "mocha" })
vim.cmd.colorscheme("catppuccin")
LUAEOF
    else
        log_step "No plugin manager detected — writing standalone config..."
        cat > "$PLUGIN_DIR/catppuccin.lua" <<'LUAEOF'
-- Catppuccin Mocha for Neovim
-- Install the plugin first: https://github.com/catppuccin/nvim
-- For lazy.nvim, this file will be auto-loaded.
return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup({ flavour = "mocha" })
    vim.cmd.colorscheme("catppuccin")
  end,
}
LUAEOF
    fi

    echo ""
    log_success "Catppuccin Neovim plugin config written to $PLUGIN_DIR/catppuccin.lua"
    log_info "Restart Neovim and the plugin will be loaded"
}

uninstall() {
    log_info "This is a config/utility script - nothing to uninstall"
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
