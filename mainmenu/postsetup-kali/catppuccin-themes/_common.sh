#!/bin/bash
# Shared functions for catppuccin-themes — sourced by all OS scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"
LOG_DIR="$MENU_ROOT/.docs/logs"
SCRIPT_NAME="catppuccin-themes"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOG_DIR"

# Shared function: Install ZSH syntax highlighting themes
install_zsh_themes() {
    log_step "Installing ZSH syntax highlighting themes..."
    mkdir -p ~/.zsh

    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    git clone --depth=1 https://github.com/catppuccin/zsh-syntax-highlighting.git catppuccin-zsh 2>/dev/null || true
    if [[ -d catppuccin-zsh/themes ]]; then
        cp catppuccin-zsh/themes/*.zsh ~/.zsh/
        log_success "ZSH syntax highlighting themes installed"
    fi

    cd ~
    rm -rf "$TEMP_DIR"

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
}

# Shared function: Install VS Code theme
install_vscode_theme() {
    if command -v code &>/dev/null; then
        log_step "Installing VS Code Catppuccin theme..."
        code --install-extension Catppuccin.catppuccin-vsc 2>/dev/null || log_warn "VS Code theme may need manual installation"
        code --install-extension Catppuccin.catppuccin-vsc-icons 2>/dev/null || true
    fi
}

# Shared function: Uninstall ZSH themes
uninstall_zsh_themes() {
    rm -f ~/.zsh/catppuccin_*.zsh

    # Remove from zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        nt_sed_i '/catppuccin_mocha-zsh-syntax-highlighting/d' "$HOME/.zshrc"
        nt_sed_i '/Catppuccin Mocha theme for zsh-syntax-highlighting/d' "$HOME/.zshrc"
    fi
}

# Shared function: Uninstall VS Code theme
uninstall_vscode_theme() {
    if command -v code &>/dev/null; then
        code --uninstall-extension Catppuccin.catppuccin-vsc 2>/dev/null || true
        code --uninstall-extension Catppuccin.catppuccin-vsc-icons 2>/dev/null || true
    fi
}

# Shared function: Print activation instructions
print_activation_instructions() {
    echo ""
    log_success "All Catppuccin themes installed!"
    echo ""
    echo "To activate themes:"
    echo ""

    if [[ "$NT_OS" == "linux" ]]; then
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
    else
        echo "1. ZSH Theme:"
        echo "   Run: source ~/.zshrc"
        echo ""
        echo "2. VS Code:"
        echo "   Cmd+Shift+P > 'Color Theme' > Catppuccin Mocha"
    fi
    echo ""
}
