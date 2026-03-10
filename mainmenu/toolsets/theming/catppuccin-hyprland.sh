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
    log_info "Running: Catppuccin Mocha theme for Hyprland"
    log_info "Log file: $LOG_FILE"
    echo ""

    # --- Hyprland color variables ---
    log_step "Writing Catppuccin Mocha color variables for Hyprland..."
    HYPR_DIR="$HOME/.config/hypr"
    mkdir -p "$HYPR_DIR"

    cat > "$HYPR_DIR/catppuccin-mocha.conf" <<'HYPREOF'
# Catppuccin Mocha colors for Hyprland
# Source this file from hyprland.conf: source = ~/.config/hypr/catppuccin-mocha.conf

$rosewater = rgb(f5e0dc)
$flamingo  = rgb(f2cdcd)
$pink      = rgb(f5c2e7)
$mauve     = rgb(cba6f7)
$red       = rgb(f38ba8)
$maroon    = rgb(eba0ac)
$peach     = rgb(fab387)
$yellow    = rgb(f9e2af)
$green     = rgb(a6e3a1)
$teal      = rgb(94e2d5)
$sky       = rgb(89dceb)
$sapphire  = rgb(74c7ec)
$blue      = rgb(89b4fa)
$lavender  = rgb(b4befe)
$text      = rgb(cdd6f4)
$subtext1  = rgb(bac2de)
$subtext0  = rgb(a6adc8)
$overlay2  = rgb(9399b2)
$overlay1  = rgb(7f849c)
$overlay0  = rgb(6c7086)
$surface2  = rgb(585b70)
$surface1  = rgb(45475a)
$surface0  = rgb(313244)
$base      = rgb(1e1e2e)
$mantle    = rgb(181825)
$crust     = rgb(11111b)
HYPREOF

    # Source from hyprland.conf if not already
    if [[ -f "$HYPR_DIR/hyprland.conf" ]]; then
        if ! grep -q "catppuccin-mocha" "$HYPR_DIR/hyprland.conf" 2>/dev/null; then
            echo "source = ~/.config/hypr/catppuccin-mocha.conf" >> "$HYPR_DIR/hyprland.conf"
        fi
    fi

    # --- Waybar CSS ---
    log_step "Writing Catppuccin Mocha CSS for Waybar..."
    WAYBAR_DIR="$HOME/.config/waybar"
    mkdir -p "$WAYBAR_DIR"

    cat > "$WAYBAR_DIR/catppuccin-mocha.css" <<'WAYEOF'
/* Catppuccin Mocha palette for Waybar */
@define-color rosewater #f5e0dc;
@define-color flamingo  #f2cdcd;
@define-color pink      #f5c2e7;
@define-color mauve     #cba6f7;
@define-color red       #f38ba8;
@define-color maroon    #eba0ac;
@define-color peach     #fab387;
@define-color yellow    #f9e2af;
@define-color green     #a6e3a1;
@define-color teal      #94e2d5;
@define-color sky       #89dceb;
@define-color sapphire  #74c7ec;
@define-color blue      #89b4fa;
@define-color lavender  #b4befe;
@define-color text      #cdd6f4;
@define-color subtext1  #bac2de;
@define-color subtext0  #a6adc8;
@define-color overlay2  #9399b2;
@define-color overlay1  #7f849c;
@define-color overlay0  #6c7086;
@define-color surface2  #585b70;
@define-color surface1  #45475a;
@define-color surface0  #313244;
@define-color base      #1e1e2e;
@define-color mantle    #181825;
@define-color crust     #11111b;
WAYEOF

    # Import into waybar style.css
    if [[ -f "$WAYBAR_DIR/style.css" ]]; then
        if ! grep -q "catppuccin-mocha" "$WAYBAR_DIR/style.css" 2>/dev/null; then
            sed -i '1i @import "catppuccin-mocha.css";' "$WAYBAR_DIR/style.css"
        fi
    else
        echo '@import "catppuccin-mocha.css";' > "$WAYBAR_DIR/style.css"
    fi

    # --- Wofi CSS ---
    log_step "Writing Catppuccin Mocha CSS for Wofi..."
    WOFI_DIR="$HOME/.config/wofi"
    mkdir -p "$WOFI_DIR"

    cat > "$WOFI_DIR/catppuccin-mocha.css" <<'WOFIEOF'
/* Catppuccin Mocha for Wofi */
window {
    background-color: #1e1e2e;
    color: #cdd6f4;
    border: 2px solid #cba6f7;
    border-radius: 8px;
}

#input {
    background-color: #313244;
    color: #cdd6f4;
    border: 1px solid #45475a;
    border-radius: 4px;
    padding: 8px;
}

#entry:selected {
    background-color: #45475a;
    color: #cdd6f4;
    border-radius: 4px;
}

#entry {
    padding: 4px 8px;
}
WOFIEOF

    # Import into wofi style.css
    if [[ -f "$WOFI_DIR/style.css" ]]; then
        if ! grep -q "catppuccin-mocha" "$WOFI_DIR/style.css" 2>/dev/null; then
            sed -i '1i @import "catppuccin-mocha.css";' "$WOFI_DIR/style.css"
        fi
    else
        cp "$WOFI_DIR/catppuccin-mocha.css" "$WOFI_DIR/style.css"
    fi

    echo ""
    log_success "Catppuccin Mocha applied to Hyprland, Waybar, and Wofi"
    log_info "Reload Hyprland to see changes (hyprctl reload)"
}

uninstall() {
    log_info "This is a config/utility script - nothing to uninstall"
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
