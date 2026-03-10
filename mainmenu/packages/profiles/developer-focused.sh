#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="developer-focused"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Bundle: Hyprland + kitty + full dev tools + Catppuccin theming
SCRIPTS=(
    "mainmenu/desktops/environments/hyprland/linux.sh"
    "mainmenu/toolsets/terminals/kitty.sh"
    "mainmenu/toolsets/dev-tools/neovim.sh"
    "mainmenu/toolsets/dev-tools/tmux.sh"
    "mainmenu/toolsets/dev-tools/ripgrep.sh"
    "mainmenu/toolsets/dev-tools/fd.sh"
    "mainmenu/toolsets/dev-tools/fzf.sh"
    "mainmenu/toolsets/dev-tools/bat.sh"
    "mainmenu/toolsets/dev-tools/lazygit.sh"
    "mainmenu/toolsets/theming/catppuccin-terminals.sh"
    "mainmenu/toolsets/theming/catppuccin-neovim.sh"
    "mainmenu/toolsets/theming/catppuccin-tmux.sh"
    "mainmenu/toolsets/theming/catppuccin-hyprland.sh"
)

install() {
    log_info "Installing Developer Focused bundle"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    local FAILED=()
    local SUCCEEDED=()

    for script in "${SCRIPTS[@]}"; do
        local path="$MENU_ROOT/$script"
        local name
        name="$(basename "$script" .sh)"
        echo ""
        log_step "===== Installing $name ====="
        if bash "$path" install; then
            SUCCEEDED+=("$name")
        else
            log_error "Failed to install $name — continuing with remaining tools"
            FAILED+=("$name")
        fi
    done

    echo ""
    echo "============================================"
    log_success "Developer Focused bundle installation complete"
    echo ""
    log_info "Succeeded: ${SUCCEEDED[*]:-none}"
    if [[ ${#FAILED[@]} -gt 0 ]]; then
        log_error "Failed: ${FAILED[*]}"
    fi
    echo "============================================"

    mark_installed true
}

uninstall() {
    log_info "Uninstalling Developer Focused bundle"
    require_root

    # Uninstall in reverse order
    local reversed=()
    for ((i=${#SCRIPTS[@]}-1; i>=0; i--)); do
        reversed+=("${SCRIPTS[$i]}")
    done

    for script in "${reversed[@]}"; do
        local path="$MENU_ROOT/$script"
        local name
        name="$(basename "$script" .sh)"
        echo ""
        log_step "===== Uninstalling $name ====="
        bash "$path" uninstall || {
            log_error "Failed to uninstall $name — continuing"
        }
    done

    echo ""
    log_success "Developer Focused bundle uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
