#!/bin/bash
# Linux implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
exec > >(tee -a "$LOG_FILE") 2>&1

require_linux "Catppuccin KDE theme requires Linux"

install() {
    log_info "Installing Catppuccin Mocha theme for KDE..."
    log_info "Log file: $LOG_FILE"
    echo ""

    log_step "Installing Kvantum theme engine..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y qt5-style-kvantum qt5-style-kvantum-themes 2>/dev/null || \
            sudo apt-get install -y kvantum 2>/dev/null || true
    fi

    log_step "Cloning Catppuccin KDE theme..."
    rm -rf "$CATPPUCCIN_KDE_DIR"
    git clone --depth 1 "$CATPPUCCIN_KDE_REPO" "$CATPPUCCIN_KDE_DIR"

    log_step "Installing color scheme..."
    mkdir -p "$HOME/.local/share/color-schemes"
    if [[ -d "$CATPPUCCIN_KDE_DIR/Resources/color-schemes" ]]; then
        cp -r "$CATPPUCCIN_KDE_DIR/Resources/color-schemes/"*Mocha* "$HOME/.local/share/color-schemes/" 2>/dev/null || true
    fi

    log_step "Installing Kvantum theme..."
    mkdir -p "$HOME/.config/Kvantum"
    if [[ -d "$CATPPUCCIN_KDE_DIR/Resources/Kvantum" ]]; then
        cp -r "$CATPPUCCIN_KDE_DIR/Resources/Kvantum/"*Mocha* "$HOME/.config/Kvantum/" 2>/dev/null || true
    fi

    # Clean up
    rm -rf "$CATPPUCCIN_KDE_DIR"

    echo ""
    log_success "Catppuccin KDE theme installed"
    log_info "Apply the theme via System Settings -> Appearance -> Colors"
    log_info "For Kvantum: run kvantummanager and select CatppuccinMocha"
    mark_installed true
}

uninstall() {
    log_info "Removing Catppuccin KDE theme..."

    rm -rf "$HOME/.local/share/color-schemes/"Catppuccin*Mocha*
    rm -rf "$HOME/.config/Kvantum/"*Mocha*

    log_success "Catppuccin KDE theme removed"
    mark_installed false
}

ACTION="${1:-install}"
case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
