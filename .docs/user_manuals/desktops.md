# Desktops - User Guide

## Overview

The Desktops menu provides installers for Linux desktop environments and display managers. Each script handles package installation, service enablement, and basic configuration.

## Available Desktop Environments

### KDE Plasma

A full-featured desktop environment with modern Wayland support. Includes Dolphin file manager, Konsole terminal, and Spectacle screenshot tool.

**Installation:**
1. Run `ninjamenu` -> Desktops -> Desktop Environments -> KDE Plasma
2. Reboot to start using KDE Plasma

**What gets installed:**
- Plasma Desktop shell and KWin Wayland compositor
- SDDM display manager (auto-enabled)
- Dolphin, Konsole, Spectacle, System Settings
- Network Manager and PulseAudio Plasma widgets

**After install:**
- SDDM login screen appears on boot
- Select "Plasma (Wayland)" or "Plasma (X11)" at the session selector

### Cinnamon

A traditional desktop forked from GNOME 3, offering a familiar Windows-like workflow with a taskbar, system tray, and start menu.

**Installation:**
1. Run `ninjamenu` -> Desktops -> Desktop Environments -> Cinnamon
2. Reboot to start using Cinnamon

**What gets installed:**
- Cinnamon desktop and session manager
- Nemo file manager
- LightDM display manager (auto-enabled)
- XApps common utilities

**After install:**
- LightDM login screen appears on boot
- Select "Cinnamon" at the session selector

### Hyprland

A dynamic tiling Wayland compositor with smooth animations. Best suited for users comfortable with keyboard-driven workflows and manual configuration.

**Installation:**
1. Run `ninjamenu` -> Desktops -> Desktop Environments -> Hyprland
2. The script checks repository availability first
3. A default `~/.config/hypr/hyprland.conf` is generated if none exists

**What gets installed:**
- Hyprland compositor
- Waybar (status bar), Wofi (launcher), Mako (notifications)
- Thunar file manager, PipeWire audio
- XDG Desktop Portal for screen sharing

**Default keybindings:**
| Key | Action |
|-----|--------|
| SUPER + Return | Open terminal (Thunar) |
| SUPER + D | App launcher (Wofi) |
| SUPER + Q | Close window |
| SUPER + V | Toggle floating |
| SUPER + 1-0 | Switch workspace |
| SUPER + SHIFT + 1-0 | Move window to workspace |
| SUPER + Arrow keys | Move focus |

**After install:**
- Select "Hyprland" from your display manager session list
- Or start from a TTY: `Hyprland`
- Edit `~/.config/hypr/hyprland.conf` to customize

**Note:** Hyprland may not be available in older distribution repositories. The installer checks `apt-cache` first and provides manual install instructions if the package is missing.

## Available Display Managers

### SDDM

The Simple Desktop Display Manager, commonly used with KDE Plasma. Includes the Breeze theme.

**Installation:**
1. Run `ninjamenu` -> Desktops -> Display Managers -> SDDM
2. Reboot to use SDDM as your login screen

**What gets installed:**
- SDDM display manager
- Breeze theme for SDDM

## Prerequisites

- Root/sudo access
- Debian-based system (Kali, Debian, Ubuntu)
- Internet connection for downloading packages

## Troubleshooting

### Display manager conflict

If you have multiple display managers installed (SDDM, LightDM, GDM3), only one can be active. Use `dpkg-reconfigure` to select the default:
```bash
sudo dpkg-reconfigure sddm    # or lightdm, gdm3
```

### Hyprland not available in repositories

Hyprland requires relatively new packaging. On Debian Stable or older Ubuntu, it may not be available. Options:
- Upgrade to Debian Sid/Trixie or Ubuntu 24.04+
- Build from source: https://wiki.hyprland.org/Getting-Started/Installation/

### Black screen after install

If you get a black screen after reboot, switch to a TTY (Ctrl+Alt+F2), log in, and check the display manager status:
```bash
systemctl status sddm     # or lightdm
journalctl -u sddm -b     # check logs
```

### Desktop environment not in session list

Ensure the `.desktop` session file exists:
```bash
ls /usr/share/xsessions/       # X11 sessions
ls /usr/share/wayland-sessions/ # Wayland sessions
```

## See Also

- [Technical Manual](../technical_manuals/desktops.md)
