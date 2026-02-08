#!/bin/bash
# ---
# name: "Catppuccin Themes"
# description: "Installs Catppuccin themes for Terminal, GTK, ZSH, and VS Code"
# version: "1.0.0"
# author: "System"
# root: false
# order: 30
# hidden: false
# installed: false
# check_command: ""
# check_path: "~/.themes/catppuccin-mocha-blue-standard+default"
# dependencies:
#   - curl
#   - git
#   - unzip
# tags:
#   - themes
#   - appearance
#   - catppuccin
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
    log_info "Installing Catppuccin Themes..."
    log_info "Log file: $LOG_FILE"

    # Create directories
    mkdir -p ~/.themes
    mkdir -p ~/.zsh

    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    #######################################
    # XFCE4 Terminal themes (Linux only)
    #######################################
    if [[ "$NT_OS" == "linux" ]]; then
        log_step "Installing XFCE4 Terminal themes..."
        mkdir -p ~/.local/share/xfce4/terminal/colorschemes
        curl -sLO https://raw.githubusercontent.com/catppuccin/xfce4-terminal/main/themes/catppuccin-mocha.theme
        curl -sLO https://raw.githubusercontent.com/catppuccin/xfce4-terminal/main/themes/catppuccin-macchiato.theme
        curl -sLO https://raw.githubusercontent.com/catppuccin/xfce4-terminal/main/themes/catppuccin-frappe.theme
        curl -sLO https://raw.githubusercontent.com/catppuccin/xfce4-terminal/main/themes/catppuccin-latte.theme
        mv catppuccin-*.theme ~/.local/share/xfce4/terminal/colorschemes/
        log_success "XFCE4 Terminal themes installed"

        #######################################
        # GTK themes (Linux only)
        #######################################
        log_step "Installing GTK themes..."
        curl -sLO "https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-mocha-blue-standard+default.zip"
        curl -sLO "https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-macchiato-blue-standard+default.zip"
        unzip -qo "catppuccin-mocha-blue-standard+default.zip" -d ~/.themes/
        unzip -qo "catppuccin-macchiato-blue-standard+default.zip" -d ~/.themes/
        log_success "GTK themes installed"
    else
        log_info "Skipping XFCE4/GTK themes (Linux only)"
    fi

    #######################################
    # ZSH syntax highlighting themes
    #######################################
    log_step "Installing ZSH syntax highlighting themes..."
    git clone --depth=1 https://github.com/catppuccin/zsh-syntax-highlighting.git catppuccin-zsh 2>/dev/null || true
    if [[ -d catppuccin-zsh/themes ]]; then
        cp catppuccin-zsh/themes/*.zsh ~/.zsh/
        log_success "ZSH syntax highlighting themes installed"
    fi

    # Add to zshrc if not present
    if [[ -f "$HOME/.zshrc" ]] && ! grep -q "catppuccin_mocha-zsh-syntax-highlighting" "$HOME/.zshrc"; then
        cat >> "$HOME/.zshrc" << 'EOF'

# Catppuccin Mocha theme for zsh-syntax-highlighting
if [ -f ~/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh ]; then
    source ~/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh
fi
EOF
        log_success "Added Catppuccin theme to .zshrc"
    fi

    #######################################
    # VS Code theme
    #######################################
    if command -v code &>/dev/null; then
        log_step "Installing VS Code Catppuccin theme..."
        code --install-extension Catppuccin.catppuccin-vsc 2>/dev/null || log_warn "VS Code theme may need manual installation"
        code --install-extension Catppuccin.catppuccin-vsc-icons 2>/dev/null || true
    fi

    # Cleanup
    cd ~
    rm -rf "$TEMP_DIR"

    echo ""
    log_success "All Catppuccin themes installed!"
    echo ""
    echo "To activate themes:"
    echo ""
    echo "1. XFCE4 Terminal:"
    echo "   Edit > Preferences > Colors > Load Presets > Catppuccin Mocha"
    echo ""
    echo "2. GTK/Desktop Theme:"
    echo "   Settings > Appearance > Style > catppuccin-mocha-blue-standard+default"
    echo ""
    echo "3. ZSH Theme:"
    echo "   Run: source ~/.zshrc"
    echo ""
    echo "4. VS Code:"
    echo "   Ctrl+Shift+P > 'Color Theme' > Catppuccin Mocha"
    echo ""

    mark_installed true
}

uninstall() {
    log_info "Removing Catppuccin Themes..."

    # Remove terminal themes
    rm -f ~/.local/share/xfce4/terminal/colorschemes/catppuccin-*.theme

    # Remove GTK themes
    rm -rf ~/.themes/catppuccin-*

    # Remove ZSH themes
    rm -f ~/.zsh/catppuccin_*.zsh

    # Remove from zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        nt_sed_i '/catppuccin_mocha-zsh-syntax-highlighting/d' "$HOME/.zshrc"
        nt_sed_i '/Catppuccin Mocha theme for zsh-syntax-highlighting/d' "$HOME/.zshrc"
    fi

    # VS Code extension
    if command -v code &>/dev/null; then
        code --uninstall-extension Catppuccin.catppuccin-vsc 2>/dev/null || true
        code --uninstall-extension Catppuccin.catppuccin-vsc-icons 2>/dev/null || true
    fi

    log_success "Catppuccin themes removed"

    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
