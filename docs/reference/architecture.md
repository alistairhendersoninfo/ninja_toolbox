---
layout: default
title: Architecture
parent: Documentation
nav_order: 4
---

<div style="float: right; margin-left: 1rem; text-align: center;">
  <img src="{{ '/assets/images/it_nerd_14213d.png' | relative_url }}" alt="IT Nerd" style="width: 110px; border-radius: 8px;" />
  <img src="{{ '/assets/images/it_super_nerd_14213d.png' | relative_url }}" alt="IT Super Nerd" style="width: 110px; border-radius: 8px; margin-top: 0.5rem;" />
</div>

# Architecture

## Overview

NinjaMenu is built around a simple principle: **folders become menus, scripts become menu items**. The directory structure under `mainmenu/` defines the entire menu hierarchy. No configuration files, no databases -- just folders and shell scripts.

## Core Components

```
ninja_toolbox/
├── .app/menu.py         # Main Python TUI application (1,100+ lines)
├── .app/menu             # Launcher script
├── install_menu.sh      # Bootstrap installer
├── .lib/platform.sh     # Cross-platform abstraction layer
├── mainmenu/            # Menu definition (folder structure)
├── .configs/            # Configuration files
├── .docs/               # Documentation and logs
├── .preinstalls/        # Pre-installation hooks
└── .postinstalls/       # Post-installation hooks
```

## Menu Generation

The menu system scans directories recursively. Dot-prefixed items (`.configs`, `.docs`) are hidden from the menu.

```
Folder scan algorithm:
1. List directory entries
2. Skip entries starting with "."
3. Folders -> submenus (titlecased name)
4. .sh files -> menu items (name from YAML header)
5. Sort by: submenus first, then by "order" field, then alphabetically
```

## YAML Header Parser

Every script contains metadata in a YAML block between `# ---` markers:

```bash
# ---
# name: "htop"
# description: "Interactive process viewer"
# type: install
# root: true
# order: 10
# check_command: "htop --version"
# ---
```

The parser uses regex to extract this block:

```python
pattern = r'^#\s*---\s*\n((?:#.*\n)*?)#\s*---'
```

### Header Fields

| Field | Type | Purpose |
|-------|------|---------|
| `name` | string | Display name in menu |
| `description` | string | Shown in detail view |
| `type` | string | `install`, `config`, or `tool` |
| `root` | boolean | Needs sudo |
| `order` | integer | Sort position (lower = higher) |
| `check_command` | string | Verify installation (e.g., `htop --version`) |
| `check_path` | string | Alternative: check if file exists |
| `binary` | string | Required command for `tool` type scripts |
| `hidden` | boolean | Hide from menu |
| `installed` | boolean | Tracks install state |

## Script Types

- **`install`** -- Shows Install/Uninstall actions. Tracks installation state via `mark_installed`.
- **`config`** -- Shows "Run" action only. For utilities and configuration scripts.
- **`tool`** -- Educational scripts. Requires `binary:` field. Shows whether the required binary is available.

## TUI Backend Selection

NinjaMenu supports three interfaces, selected in `.configs/menusystem/settings.conf`:

| Backend | Description | Requirement |
|---------|-------------|-------------|
| `gum` | Modern Charm.sh prompts (default) | `gum` binary |
| `whiptail` | Classic ncurses dialogs | `whiptail` or `dialog` |
| `textual` | Full Python TUI with mouse | Python textual package |

## Platform Library (`.lib/platform.sh`)

The shared library provides cross-platform abstractions:

### Variables

| Variable | Values |
|----------|--------|
| `$NT_OS` | `"linux"` or `"macos"` |
| `$NT_DISTRO` | `"debian"`, `"kali"`, `"ubuntu"`, or `"macos"` |
| `$NT_ARCH` | `"x86_64"`, `"arm64"`, `"aarch64"` |

### Functions

| Function | Purpose |
|----------|---------|
| `pkg_install pkg` | Install package (apt on Linux, brew on macOS) |
| `pkg_remove pkg` | Remove package |
| `pkg_update` | Update package cache |
| `require_root` | Check/enforce root privileges |
| `require_linux "msg"` | Guard Linux-only scripts |
| `mark_installed true/false` | Update YAML installed state |
| `nt_sed_i 'expr' file` | Cross-platform sed in-place |
| `log_info`, `log_success`, `log_warn`, `log_error` | Coloured logging |

### Package Name Mapping

Some packages have different names across platforms. `pkg_install` handles this automatically:

| Linux Package | macOS Equivalent |
|---------------|-----------------|
| `net-tools` | `iproute2mac` |
| `wireshark` | `--cask wireshark` |
| `zenmap` | `--cask zenmap` |

## Hook System

### Pre-install Hooks (`.preinstalls/`)

Run before any installation: dependency checking, system preparation, user confirmation.

### Post-install Hooks (`.postinstalls/`)

Run after installations: PATH updates, configuration adjustments, cleanup.

## Logging

All scripts log to `.docs/logs/` with timestamps:

```bash
LOG_DIR="$MENU_ROOT/.docs/logs"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
```

## Installation State

Scripts update their own YAML header using `mark_installed`:

```bash
mark_installed true   # Sets "# installed: true" in the script
mark_installed false  # Sets "# installed: false" in the script
```

The menu reads this field to show checkmarks next to installed items.

## API Reference

### ScriptInfo

```python
@dataclass
class ScriptInfo:
    path: Path
    name: str
    description: str
    version: str
    author: str
    root: bool
    order: int
    hidden: bool
    installed: bool
    uninstall: str
    dependencies: List[str]
    tags: List[str]
```

### Key Functions

| Function | Description |
|----------|-------------|
| `parse_yaml_header(path)` | Extract YAML metadata from script |
| `scan_menu_directory(dir)` | Get all menu items from folder |
| `run_script(info, action)` | Execute a script with logging |
| `view_log(name)` | Display most recent log file |
