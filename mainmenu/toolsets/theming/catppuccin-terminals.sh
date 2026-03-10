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
    log_info "Running: Catppuccin Mocha theme for terminal emulators"
    log_info "Log file: $LOG_FILE"
    echo ""

    local configured=0

    # --- kitty ---
    if command -v kitty &>/dev/null; then
        log_step "Configuring kitty..."
        mkdir -p "$HOME/.config/kitty"
        cat > "$HOME/.config/kitty/catppuccin-mocha.conf" <<'KITTYEOF'
# Catppuccin Mocha for kitty
# https://github.com/catppuccin/kitty

foreground              #CDD6F4
background              #1E1E2E
selection_foreground    #1E1E2E
selection_background    #F5E0DC

cursor                  #F5E0DC
cursor_text_color       #1E1E2E

url_color               #F5E0DC

active_tab_foreground   #11111B
active_tab_background   #CBA6F7
inactive_tab_foreground #CDD6F4
inactive_tab_background #181825

# black
color0  #45475A
color8  #585B70
# red
color1  #F38BA8
color9  #F38BA8
# green
color2  #A6E3A1
color10 #A6E3A1
# yellow
color3  #F9E2AF
color11 #F9E2AF
# blue
color4  #89B4FA
color12 #89B4FA
# magenta
color5  #F5C2E7
color13 #F5C2E7
# cyan
color6  #94E2D5
color14 #94E2D5
# white
color7  #BAC2DE
color15 #A6ADC8
KITTYEOF
        # Source from main config if not already
        if [[ -f "$HOME/.config/kitty/kitty.conf" ]]; then
            if ! grep -q "catppuccin-mocha" "$HOME/.config/kitty/kitty.conf" 2>/dev/null; then
                echo "include catppuccin-mocha.conf" >> "$HOME/.config/kitty/kitty.conf"
            fi
        else
            echo "include catppuccin-mocha.conf" > "$HOME/.config/kitty/kitty.conf"
        fi
        configured=$((configured + 1))
        log_info "kitty: catppuccin-mocha.conf written"
    fi

    # --- wezterm ---
    if command -v wezterm &>/dev/null; then
        log_step "Configuring WezTerm..."
        mkdir -p "$HOME/.config/wezterm/colors"
        cat > "$HOME/.config/wezterm/colors/catppuccin-mocha.toml" <<'WEZEOF'
[colors]
foreground = "#CDD6F4"
background = "#1E1E2E"
cursor_bg = "#F5E0DC"
cursor_fg = "#1E1E2E"
cursor_border = "#F5E0DC"
selection_fg = "#1E1E2E"
selection_bg = "#F5E0DC"

ansi = ["#45475A", "#F38BA8", "#A6E3A1", "#F9E2AF", "#89B4FA", "#F5C2E7", "#94E2D5", "#BAC2DE"]
brights = ["#585B70", "#F38BA8", "#A6E3A1", "#F9E2AF", "#89B4FA", "#F5C2E7", "#94E2D5", "#A6ADC8"]
WEZEOF
        configured=$((configured + 1))
        log_info "WezTerm: catppuccin-mocha.toml written to colors directory"
        log_info "Add 'color_scheme = \"catppuccin-mocha\"' to your wezterm.lua"
    fi

    # --- alacritty ---
    if command -v alacritty &>/dev/null; then
        log_step "Configuring Alacritty..."
        mkdir -p "$HOME/.config/alacritty"
        cat > "$HOME/.config/alacritty/catppuccin-mocha.toml" <<'ALAEOF'
# Catppuccin Mocha for Alacritty
# https://github.com/catppuccin/alacritty

[colors.primary]
background = "#1E1E2E"
foreground = "#CDD6F4"
dim_foreground = "#CDD6F4"
bright_foreground = "#CDD6F4"

[colors.cursor]
text = "#1E1E2E"
cursor = "#F5E0DC"

[colors.vi_mode_cursor]
text = "#1E1E2E"
cursor = "#B4BEFE"

[colors.search.matches]
foreground = "#1E1E2E"
background = "#A6ADC8"

[colors.search.focused_match]
foreground = "#1E1E2E"
background = "#A6E3A1"

[colors.footer_bar]
foreground = "#1E1E2E"
background = "#A6ADC8"

[colors.hints.start]
foreground = "#1E1E2E"
background = "#F9E2AF"

[colors.hints.end]
foreground = "#1E1E2E"
background = "#A6ADC8"

[colors.selection]
text = "#1E1E2E"
background = "#F5E0DC"

[colors.normal]
black = "#45475A"
red = "#F38BA8"
green = "#A6E3A1"
yellow = "#F9E2AF"
blue = "#89B4FA"
magenta = "#F5C2E7"
cyan = "#94E2D5"
white = "#BAC2DE"

[colors.bright]
black = "#585B70"
red = "#F38BA8"
green = "#A6E3A1"
yellow = "#F9E2AF"
blue = "#89B4FA"
magenta = "#F5C2E7"
cyan = "#94E2D5"
white = "#A6ADC8"

[colors.dim]
black = "#45475A"
red = "#F38BA8"
green = "#A6E3A1"
yellow = "#F9E2AF"
blue = "#89B4FA"
magenta = "#F5C2E7"
cyan = "#94E2D5"
white = "#BAC2DE"
ALAEOF
        # Import into main config if alacritty.toml exists
        if [[ -f "$HOME/.config/alacritty/alacritty.toml" ]]; then
            if ! grep -q "catppuccin-mocha" "$HOME/.config/alacritty/alacritty.toml" 2>/dev/null; then
                # Prepend import directive
                sed -i '1i import = ["~/.config/alacritty/catppuccin-mocha.toml"]' "$HOME/.config/alacritty/alacritty.toml"
            fi
        else
            echo 'import = ["~/.config/alacritty/catppuccin-mocha.toml"]' > "$HOME/.config/alacritty/alacritty.toml"
        fi
        configured=$((configured + 1))
        log_info "Alacritty: catppuccin-mocha.toml written and imported"
    fi

    echo ""
    if [[ $configured -eq 0 ]]; then
        log_info "No supported terminals found (kitty, wezterm, alacritty)"
        log_info "Install a terminal first, then re-run this script"
    else
        log_success "Catppuccin Mocha applied to $configured terminal(s)"
    fi
}

uninstall() {
    log_info "This is a config/utility script - nothing to uninstall"
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
