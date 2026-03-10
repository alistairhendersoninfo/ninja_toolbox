# Packages - User Guide

## Overview

Packages provides pre-configured environment bundles that install a complete desktop setup in one step. Instead of installing individual tools, choose a profile that matches your workflow and get everything configured with consistent Catppuccin theming.

## Available Profiles

### Desktop Workstation

**What it does:** Installs a full KDE Plasma desktop with essential development tools and Catppuccin Mocha theming applied everywhere.

**Includes:**
- KDE Plasma desktop environment with SDDM
- Neovim text editor
- tmux terminal multiplexer
- Catppuccin Mocha theme for KDE, Neovim, and tmux

**How to use:**
1. Run `ninjamenu`
2. Navigate to Packages → Environment Profiles → Desktop Workstation
3. Select Install and wait for all components to complete
4. Reboot to start using KDE Plasma

### Developer Focused

**What it does:** Installs a Hyprland tiling window manager with a complete developer toolchain and Catppuccin theming.

**Includes:**
- Hyprland tiling compositor with waybar and wofi
- kitty GPU-accelerated terminal
- Neovim, tmux, ripgrep, fd, fzf, bat, lazygit
- Catppuccin Mocha theme for terminals, Neovim, tmux, and Hyprland

**How to use:**
1. Run `ninjamenu`
2. Navigate to Packages → Environment Profiles → Developer Focused
3. Select Install and wait for all components to complete
4. Log out and select the Hyprland session from your display manager

## Common Tasks

### Uninstalling a Bundle

Each bundle can be fully uninstalled in reverse order:
1. Navigate to the bundle in the menu
2. Select Uninstall
3. All components are removed in reverse installation order

### Installing Individual Components

If you only want specific tools from a bundle, install them individually from the Desktops or Toolsets categories instead.

## Troubleshooting

### A component fails during bundle install

The bundle continues installing remaining components even if one fails. Check the log file for details on the failure, then install the failed component individually after fixing the issue.

### Hyprland not available in package repos

On older Debian/Ubuntu versions, Hyprland may not be in the default repositories. The Developer Focused bundle will report this error. See the Hyprland script output for manual installation instructions.

## See Also

- [Technical Manual](../technical_manuals/packages.md)
- [Desktops User Guide](./desktops.md)
- [Toolsets User Guide](./toolsets.md)
