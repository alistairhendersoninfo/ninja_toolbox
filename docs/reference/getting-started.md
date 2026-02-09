---
layout: default
title: Getting Started
parent: Documentation
nav_order: 1
---

<img src="{{ '/assets/images/little_tracey_ninja_14213d.png' | relative_url }}" alt="Little Tracey Ninja" style="float: right; width: 120px; margin-left: 1rem;" />

# Getting Started

## Installation

```bash
git clone https://github.com/alistairhendersoninfo/ninja_toolbox.git
cd ninja_toolbox

# Linux (Kali/Debian/Ubuntu) -- requires sudo
sudo ./install_menu.sh

# macOS (Intel or Apple Silicon) -- do NOT use sudo
./install_menu.sh
```

The installer handles everything: Python 3.8+, virtual environment, gum, dialog, and all Python dependencies (textual, pyyaml, rich).

## Launch the Menu

```bash
ninjamenu
```

Or from the install directory:

```bash
./menu
```

## Navigation

| Key | Action |
|-----|--------|
| `1-99` | Jump to item by number |
| Arrow keys | Navigate up/down |
| `Enter` | Select item |
| `b` | Go back |
| `x` | Exit |
| `l` | View installation log |

## Menu Icons

| Icon | Meaning |
|------|---------|
| Folder icon | Submenu (folder) |
| Empty box | Not installed |
| Checkmark | Installed |
| Lock | Requires root/sudo |

## Installing Software

1. Navigate to the desired category
2. Select the software to install
3. Choose "Install" from the action menu
4. Wait for installation to complete
5. Press Enter to return to menu

## Uninstalling Software

1. Navigate to an installed item (shows checkmark)
2. Select the item
3. Choose "Uninstall" from the action menu
4. Confirm the uninstallation

## Command Line Options

```bash
ninjamenu                          # Interactive menu
ninjamenu --list                   # Show all available scripts
ninjamenu --submenu network        # Jump to a category
ninjamenu --tui gum                # Force a specific interface
ninjamenu --tui whiptail           # Classic ncurses mode
ninjamenu --tui textual            # Full Python TUI
ninjamenu --run monitoring/htop.sh # Run a script directly
```

## Switching Interfaces

Edit `.configs/menusystem/settings.conf`:

```conf
backend=gum        # Modern (default)
backend=whiptail   # Classic ncurses
backend=textual    # Full Python TUI
```

## Viewing Logs

Logs are stored in `.docs/logs/` with timestamps:

```bash
ls .docs/logs/
less .docs/logs/htop_20260208_153200.log
```

Or select an item in the menu and choose "View Log".

## Adding Your Own Scripts

Drop a `.sh` file in any folder under `mainmenu/` with a YAML header:

```bash
#!/bin/bash
# ---
# name: "My Tool"
# description: "What it does"
# type: install
# root: true
# order: 20
# check_command: "mytool --version"
# tags: "category, keyword"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_install mytool
    log_success "mytool installed!"
else
    require_root
    pkg_remove mytool
fi
```

That's it. The menu discovers new scripts automatically.

## Troubleshooting

### Menu doesn't start

1. Ensure you've run the installer: `sudo ./install_menu.sh` (Linux) or `./install_menu.sh` (macOS)
2. Try forcing whiptail: `ninjamenu --tui whiptail`

### Script fails with permission error

Scripts marked with a lock icon require sudo. The menu handles this automatically.

### Command not found after install

Restart your terminal or run `source ~/.bashrc` (or `source ~/.zshrc`).
