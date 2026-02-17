# OS-Modular Script Architecture

> **Audience:** LLMs, AI coding assistants, and developers contributing scripts to NinjaMenu.
> This document is the single source of truth for how scripts are structured, named, and organised.

## Overview

NinjaMenu uses a **three-tier metadata system** for scripts. Every script has externalised metadata (YAML) and uses the cross-platform `platform.sh` library for OS abstraction. Scripts that need genuinely different code per OS use a modular folder structure; scripts that are OS-agnostic use a simpler sibling metadata file.

## Three-Tier System

### Tier 1: Modular Folders (OS-specific scripts)

For scripts with genuinely different code per OS (e.g., different package managers, different install methods).

```
mainmenu/<category>/<tool-name>/
├── meta.yaml        # Metadata — name, description, order, tags, supported_os
├── _common.sh       # Shared functions sourced by all OS scripts
├── macos.sh         # macOS implementation
├── linux.sh         # Generic Linux implementation (apt-based)
├── kali-linux.sh    # Kali-specific implementation (optional, if differs from linux.sh)
└── debian.sh        # Debian-specific implementation (optional)
```

**When to use:** The script has `case $NT_OS` or `case $NT_DISTRO` blocks with substantially different logic per OS. Examples: `git-setup`, `nodejs`, `cursor`, `nmap-tools-bundle`.

### Tier 2: Sibling `.meta.yaml` (OS-agnostic scripts)

For scripts that work across all supported OSes via `platform.sh`'s `pkg_install`/`pkg_remove` abstraction.

```
mainmenu/<category>/
├── htop.sh              # The script (uses platform.sh for cross-platform support)
├── htop.meta.yaml       # Externalised metadata
├── btop.sh
├── btop.meta.yaml
└── ...
```

**When to use:** The script uses `pkg_install`/`pkg_remove` from `platform.sh` and has no OS-specific code paths. This is the majority of scripts (~71 out of 81).

### Tier 3: Legacy Inline YAML (deprecated)

Scripts with `# --- ... # ---` YAML headers embedded in the `.sh` file. This format is still supported by `menu.py` for backward compatibility but should not be used for new scripts.

## Supported Operating Systems

| OS Key | Script Filename (Tier 1) | Package Manager | Detected Via |
|--------|--------------------------|-----------------|--------------|
| `macos` | `macos.sh` | Homebrew | `uname -s` = Darwin |
| `kali` | `kali-linux.sh` | apt | `/etc/os-release` ID=kali |
| `debian` | `debian.sh` | apt | `/etc/os-release` ID=debian |
| `ubuntu` | `ubuntu.sh` | apt | `/etc/os-release` ID=ubuntu |

### Tier 1 Script Resolution

When `menu.py` encounters a Tier 1 folder, it resolves to the correct OS script:

1. **Exact distro match** — e.g., `kali-linux.sh` for Kali
2. **Distro prefix match** — e.g., `kali-linux.sh` matches `kali`
3. **Generic OS fallback** — e.g., `linux.sh` for any Linux distro
4. **Not supported** — script is hidden from menu on this OS

## meta.yaml Format (Tier 1)

Every Tier 1 folder **must** have a `meta.yaml`. This is the single source of truth for metadata — do NOT put YAML headers inside `.sh` files.

```yaml
name: "Human Readable Name"
description: "What this action does"
version: "1.0.0"
author: "Author Name"
type: install              # install (Install/Uninstall) or config (Run only)
root: false                # true if needs sudo (on Linux; macOS uses Homebrew without sudo)
order: 10                  # Sort order in menu (lower = higher)
hidden: false
installed: false
check_command: "tool --version"
check_path: "/usr/bin/tool"
dependencies:
  - package1
  - package2
tags:
  - category1
  - category2
supported_os:
  - macos
  - kali
  - debian
  - ubuntu
```

## .meta.yaml Format (Tier 2)

Sibling `.meta.yaml` files use the same YAML format as Tier 1 `meta.yaml`:

```yaml
name: "htop"
description: "Interactive process viewer with color display"
type: install
root: true
order: 10
installed: false
check_command: "htop --version"
tags:
  - monitoring
  - process
supported_os:
  - macos
  - kali
  - debian
  - ubuntu
```

### Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Display name in the menu |
| description | string | Yes | Brief description shown in the menu |
| version | string | No | Script version |
| author | string | No | Script author |
| type | string | No | `install` (Install/Uninstall) or `config` (Run only) |
| root | boolean | Yes | Whether sudo/root is required |
| order | integer | Yes | Sort order (lower number = higher in menu) |
| hidden | boolean | No | If true, exclude from menu |
| installed | boolean | No | Tracks installation state (updated by `mark_installed`) |
| check_command | string | No | Command to verify installation (e.g., `nmap --version`) |
| check_path | string | No | Path to check existence (e.g., `/usr/bin/nmap`) |
| dependencies | array | No | Required system packages |
| tags | array | No | Categorisation tags |
| supported_os | array | Yes | Which OSes this script supports |

## _common.sh Template (Tier 1)

Shared logic sourced by every OS script. Sources `platform.sh` for logging and cross-platform utilities.

```bash
#!/bin/bash
# Shared functions for <tool-name> — sourced by all OS scripts
# Do NOT add YAML headers here (use meta.yaml)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"

# Source platform detection (provides log_info, log_error, log_success, etc.)
source "$MENU_ROOT/.lib/platform.sh"

# Setup logging
LOG_DIR="$MENU_ROOT/.docs/logs"
SCRIPT_NAME="$(basename "$SCRIPT_DIR")"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
```

## OS Script Template (Tier 1)

Each OS-specific script follows this pattern:

```bash
#!/bin/bash
# OS-specific implementation — do NOT add YAML headers here (use meta.yaml)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

ACTION="${1:-install}"

case "$ACTION" in
    install)
        log_info "Installing <tool> on <os>..."
        # Use this OS's package manager:
        #   macOS:                brew install <pkg>
        #   Ubuntu/Debian/Kali:   apt-get install -y <pkg>
        mark_installed true
        log_success "<tool> installed successfully"
        ;;
    uninstall)
        log_info "Uninstalling <tool> on <os>..."
        # Reverse the install
        mark_installed false
        log_success "<tool> uninstalled successfully"
        ;;
    *)
        echo "Usage: $0 {install|uninstall}"
        exit 1
        ;;
esac
```

## How menu.py Discovers Scripts

`menu.py` scans `mainmenu/` recursively with three-way detection:

```
scan_menu_directory()
    │
    ├── Is this a DIRECTORY with meta.yaml inside?
    │   └── Yes → Tier 1 modular folder
    │       ├── Read meta.yaml for metadata
    │       ├── Resolve OS-specific script via _resolve_modular_script()
    │       └── If no matching OS script, skip (not supported on this OS)
    │
    ├── Is this a .sh file with a sibling <name>.meta.yaml?
    │   └── Yes → Tier 2 sibling metadata
    │       └── Read .meta.yaml for metadata
    │
    └── Is this a .sh file with no sibling metadata?
        └── Yes → Tier 3 legacy inline YAML
            └── Parse # --- ... # --- header from the script
```

### Installed State Tracking

`mark_installed()` in `platform.sh` writes back to the correct metadata file:

1. **Tier 1:** Writes to `meta.yaml` in the script's folder
2. **Tier 2:** Writes to sibling `.meta.yaml`
3. **Tier 3:** Writes to inline YAML header in the `.sh` file

## Rules (Must Follow)

1. **No YAML headers inside `.sh` files** — all metadata lives in `meta.yaml` or `.meta.yaml`
2. **Tier 1 folders: no `if`/`case` blocks for OS detection** — one file per OS, always
3. **Tier 1: always source `_common.sh`** at the top of every OS script
4. **Tier 2: always source `platform.sh`** for cross-platform `pkg_install`/`pkg_remove`
5. **Underscore-prefixed files** (`_common.sh`) are hidden from the menu
6. **Folder and file names**: lowercase, hyphenated (e.g., `nmap-tools-bundle`)
7. **Only list supported OSes you've tested** in `supported_os`
8. **Log everything** — use `log_info`, `log_error`, `log_success` from `platform.sh`
9. **Use `mark_installed true/false`** after install/uninstall to update metadata

## Adding a New Script

### If OS-agnostic (uses `pkg_install`/`pkg_remove`):

1. Create `mainmenu/<category>/<tool-name>.sh` using `platform.sh`
2. Create `mainmenu/<category>/<tool-name>.meta.yaml` with metadata
3. Test: `bash <tool-name>.sh install` and `bash <tool-name>.sh uninstall`

### If OS-specific (different code per OS):

1. Create folder: `mainmenu/<category>/<tool-name>/`
2. Create `meta.yaml` with metadata
3. Create `_common.sh` sourcing `platform.sh`
4. Create one `.sh` file per OS (e.g., `macos.sh`, `linux.sh`)
5. List only created OS scripts in `supported_os`
6. Test each OS script

## Current Inventory

| Tier | Count | Description |
|------|-------|-------------|
| Tier 1 (folders) | 10 | OS-specific scripts with modular folders |
| Tier 2 (sibling .meta.yaml) | 71 | OS-agnostic scripts with external metadata |
| Tier 3 (legacy) | 0 | All migrated to Tier 1 or 2 |
| **Total** | **81** | |
