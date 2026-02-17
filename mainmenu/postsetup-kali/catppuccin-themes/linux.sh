#!/bin/bash
# Linux implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing Catppuccin Themes (Linux)..."
    log_info "Log file: $LOG_FILE"

    # Create directories
    mkdir -p ~/.themes

    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    #######################################
    # XFCE4 Terminal themes (Linux only)
    #######################################
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

    # Cleanup temp directory
    cd ~
    rm -rf "$TEMP_DIR"

    #######################################
    # ZSH and VS Code themes (cross-platform)
    #######################################
    install_zsh_themes
    install_vscode_theme

    print_activation_instructions

    mark_installed true
}

uninstall() {
    log_info "Removing Catppuccin Themes..."

    # Remove terminal themes
    rm -f ~/.local/share/xfce4/terminal/colorschemes/catppuccin-*.theme

    # Remove GTK themes
    rm -rf ~/.themes/catppuccin-*

    # Remove ZSH and VS Code themes
    uninstall_zsh_themes
    uninstall_vscode_theme

    log_success "Catppuccin themes removed"

    mark_installed false
}

ACTION="${1:-install}"
case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
