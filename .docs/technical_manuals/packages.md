# Packages - Technical Manual

## Architecture

Bundle scripts orchestrate the installation of multiple individual scripts from the `desktops/` and `toolsets/` categories. They follow the same pattern as `security-bundle.sh` — looping through a list of script paths, tracking success/failure, and uninstalling in reverse order.

Bundles use `$MENU_ROOT`-based paths to reference scripts across categories, making them location-independent.

## Scripts Reference

### desktop-workstation.sh

**Purpose:** Installs KDE Plasma desktop with Neovim, tmux, and Catppuccin theming

**Location:** `mainmenu/packages/profiles/desktop-workstation.sh`

**Bundle contents (in order):**
1. `desktops/environments/kde-plasma/linux.sh` — KDE Plasma desktop
2. `toolsets/dev-tools/neovim.sh` — Neovim editor
3. `toolsets/dev-tools/tmux.sh` — Terminal multiplexer
4. `toolsets/theming/catppuccin-kde/linux.sh` — KDE Catppuccin theme
5. `toolsets/theming/catppuccin-neovim.sh` — Neovim Catppuccin colors
6. `toolsets/theming/catppuccin-tmux.sh` — tmux Catppuccin plugin

**Functions:**
- `install()` — Iterates scripts, tracks SUCCEEDED/FAILED arrays, reports summary
- `uninstall()` — Iterates scripts in reverse order

**Log Output:** `.docs/logs/desktop-workstation_YYYYMMDD_HHMMSS.log`

### developer-focused.sh

**Purpose:** Installs Hyprland tiling WM with kitty, full dev toolchain, and Catppuccin theming

**Location:** `mainmenu/packages/profiles/developer-focused.sh`

**Bundle contents (in order):**
1. `desktops/environments/hyprland/linux.sh` — Hyprland compositor
2. `toolsets/terminals/kitty.sh` — kitty terminal
3. `toolsets/dev-tools/neovim.sh` — Neovim editor
4. `toolsets/dev-tools/tmux.sh` — Terminal multiplexer
5. `toolsets/dev-tools/ripgrep.sh` — Fast grep
6. `toolsets/dev-tools/fd.sh` — Fast find
7. `toolsets/dev-tools/fzf.sh` — Fuzzy finder
8. `toolsets/dev-tools/bat.sh` — Cat with syntax highlighting
9. `toolsets/dev-tools/lazygit.sh` — Git TUI
10. `toolsets/theming/catppuccin-terminals.sh` — Terminal colors
11. `toolsets/theming/catppuccin-neovim.sh` — Neovim colors
12. `toolsets/theming/catppuccin-tmux.sh` — tmux theme
13. `toolsets/theming/catppuccin-hyprland.sh` — Hyprland/waybar/wofi theme

**Functions:**
- `install()` — Iterates scripts, tracks SUCCEEDED/FAILED arrays, reports summary
- `uninstall()` — Iterates scripts in reverse order

**Log Output:** `.docs/logs/developer-focused_YYYYMMDD_HHMMSS.log`

## Integration Points

### Cross-Category References

Bundles reference scripts using `$MENU_ROOT`-relative paths:
- `$MENU_ROOT/mainmenu/desktops/...` — Desktop environment scripts
- `$MENU_ROOT/mainmenu/toolsets/...` — Terminal, dev tool, and theming scripts

### Error Handling

- Each script is run with `bash "$path" install`
- Failures are caught and logged but do not stop the bundle
- Summary shows SUCCEEDED and FAILED arrays at completion

## Development

### Adding a New Bundle

1. Create `mainmenu/packages/profiles/<name>.sh` from the existing bundle pattern
2. Create `mainmenu/packages/profiles/<name>.meta.yaml` with required fields
3. Define the `SCRIPTS` array with `$MENU_ROOT`-relative paths
4. Test with `bash mainmenu/packages/profiles/<name>.sh install`

## Changelog

- **v1.0.0** — Initial implementation with desktop-workstation and developer-focused profiles

## See Also

- [User Guide](../user_manuals/packages.md)
