#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
PACKAGES=(htop atop btop iotop iftop neofetch inxi ncdu duf sysstat nmon glances)

if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    for pkg in "${PACKAGES[@]}"; do
        log_info "Installing $pkg..."
        pkg_install "$pkg" 2>/dev/null || log_warn "Failed: $pkg"
    done
    log_success "All monitoring tools installed!"
else
    require_root
    for pkg in "${PACKAGES[@]}"; do
        pkg_remove "$pkg" 2>/dev/null || true
    done
    log_success "All monitoring tools removed."
fi
