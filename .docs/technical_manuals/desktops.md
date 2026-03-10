# Desktops - Technical Manual

## Architecture

Desktop scripts are organized into two subcategories:

- `environments/` - Full desktop environments (Tier 1 modular scripts)
- `display-managers/` - Login screen managers (Tier 2 sibling `.meta.yaml`)

Desktop environments use Tier 1 because they are Linux-only with substantial post-install configuration. The display manager script uses Tier 2 as a straightforward package install.

```
mainmenu/desktops/
├── category.yaml
├── README.md
├── environments/
│   ├── category.yaml
│   ├── kde-plasma/          # Tier 1
│   │   ├── meta.yaml
│   │   ├── _common.sh
│   │   └── linux.sh
│   ├── cinnamon/            # Tier 1
│   │   ├── meta.yaml
│   │   ├── _common.sh
│   │   └── linux.sh
│   └── hyprland/            # Tier 1
│       ├── meta.yaml
│       ├── _common.sh
│       └── linux.sh
└── display-managers/
    ├── category.yaml
    ├── sddm.sh              # Tier 2
    └── sddm.meta.yaml
```

## Scripts Reference

### environments/kde-plasma/

**Purpose:** Install the KDE Plasma desktop with Wayland support

**Packages:**
```
plasma-desktop kwin-wayland sddm dolphin konsole kde-spectacle
system-settings plasma-nm plasma-pa
```

**Post-install actions:**
- `systemctl enable sddm` - Sets SDDM as display manager
- `systemctl set-default graphical.target` - Boot to GUI

**Check:** `plasmashell --version`

**Side effects:** Enables SDDM, which may override an existing display manager. The `graphical.target` change persists across reboots.

### environments/cinnamon/

**Purpose:** Install the Cinnamon desktop environment

**Packages:**
```
cinnamon cinnamon-core nemo cinnamon-settings-daemon cinnamon-session
xapps-common lightdm
```

**Post-install actions:**
- `systemctl enable lightdm` - Sets LightDM as display manager
- `systemctl set-default graphical.target` - Boot to GUI

**Check:** `cinnamon --version`

**Side effects:** Enables LightDM, which may override an existing display manager.

### environments/hyprland/

**Purpose:** Install the Hyprland tiling Wayland compositor

**Packages:**
```
hyprland waybar wofi mako-notifier thunar network-manager-gnome
pipewire wireplumber xdg-desktop-portal-hyprland
```

**Pre-install check:** Runs `apt-cache show hyprland` to verify package availability before attempting installation. Exits with instructions if unavailable.

**Post-install actions:**
- Scaffolds `~/.config/hypr/hyprland.conf` with sensible defaults (skipped if file exists)
- Creates `/usr/share/wayland-sessions/hyprland.desktop` if not provided by the package
- Config ownership set to `$SUDO_USER` (not root)

**Check:** `hyprctl version`

**Config file details:** The generated `hyprland.conf` includes:
- Monitor auto-detection
- Dwindle tiling layout with gaps and rounded corners
- Waybar and Mako autostart
- Standard SUPER-key bindings for window management and workspaces
- Brand colours used for border accents

### display-managers/sddm.sh

**Purpose:** Install SDDM display manager with Breeze theme

**Packages:**
```
sddm sddm-theme-breeze
```

**Post-install actions:**
- `systemctl enable sddm`

**Check:** `sddm --version`, `/usr/bin/sddm`

## Dependencies

All scripts depend on:
- `apt` package manager
- `systemctl` for service management
- `platform.sh` library (`pkg_update`, `pkg_install`, `require_root`, `require_linux`, `mark_installed`, logging functions)

## Display Manager Interactions

Installing a desktop environment may also install a display manager (SDDM with KDE, LightDM with Cinnamon). If multiple display managers are present, the system uses `update-alternatives` or `dpkg-reconfigure` to select the active one. The last `systemctl enable` wins for the default.

## Development

### Adding a New Desktop Environment

1. Create a Tier 1 folder under `environments/` (e.g., `environments/gnome/`)
2. Add `meta.yaml`, `_common.sh`, and `linux.sh`
3. Follow the existing pattern: packages array, `require_root`, `pkg_install`, service enablement
4. Set `check_command` to the desktop's version command
5. Update README.md, user manual, and technical manual

### Adding a New Display Manager

1. Create a Tier 2 script pair under `display-managers/` (e.g., `lightdm.sh` + `lightdm.meta.yaml`)
2. Follow the `sddm.sh` pattern
3. Update documentation

## See Also

- [User Guide](../user_manuals/desktops.md)
