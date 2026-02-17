# Contributing Scripts to NinjaMenu

> **For LLMs, AI coding assistants, and developers.**
> Follow this guide exactly when creating or modifying scripts in the menu system.

## Architecture

NinjaMenu uses a **three-tier metadata system**. Every script has externalised metadata (YAML) and uses the cross-platform `platform.sh` library. Scripts that need different code per OS use modular folders (Tier 1); OS-agnostic scripts use a simpler sibling metadata file (Tier 2).

Full technical reference: [`.docs/technical_manuals/os-modular-architecture.md`](../.docs/technical_manuals/os-modular-architecture.md)

## Quick Decision: Which Tier?

- **Does the script need different code per OS?** → **Tier 1** (modular folder)
- **Does the script use `pkg_install`/`pkg_remove` from `platform.sh`?** → **Tier 2** (sibling `.meta.yaml`)
- Most scripts are Tier 2 (~71 out of 81).

## Tier 1: Modular Folder (OS-specific)

```
mainmenu/<category>/<tool-name>/
├── meta.yaml        # Metadata
├── _common.sh       # Shared functions (sources platform.sh)
├── macos.sh         # macOS implementation
├── linux.sh         # Generic Linux implementation
└── kali-linux.sh    # Optional: Kali-specific (if differs from linux.sh)
```

### Adding a Tier 1 Script

1. Create folder: `mainmenu/<category>/<tool-name>/`
2. Create `meta.yaml`:

```yaml
name: "Human Readable Name"
description: "What this script does"
version: "1.0.0"
author: "Author Name"
type: install
root: false
order: 10
hidden: false
installed: false
check_command: "tool --version"
check_path: "/usr/bin/tool"
dependencies:
  - package1
tags:
  - category1
supported_os:
  - macos
  - kali
  - debian
  - ubuntu
```

3. Create `_common.sh`:

```bash
#!/bin/bash
# Shared functions — sourced by all OS scripts
# Do NOT add YAML headers here (use meta.yaml)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"

source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
SCRIPT_NAME="$(basename "$SCRIPT_DIR")"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
```

4. Create OS scripts (e.g., `macos.sh`):

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

ACTION="${1:-install}"

case "$ACTION" in
    install)
        log_info "Installing <tool> on macOS..."
        brew install <pkg>
        mark_installed true
        log_success "<tool> installed successfully"
        ;;
    uninstall)
        log_info "Uninstalling <tool> from macOS..."
        brew uninstall <pkg>
        mark_installed false
        log_success "<tool> uninstalled successfully"
        ;;
    *)
        echo "Usage: $0 {install|uninstall}"
        exit 1
        ;;
esac
```

5. Update `supported_os` in `meta.yaml` to list only the OS scripts you created
6. Test: `bash <os>.sh install` and `bash <os>.sh uninstall`

## Tier 2: Sibling .meta.yaml (OS-agnostic)

```
mainmenu/<category>/
├── htop.sh              # Script (uses platform.sh)
├── htop.meta.yaml       # Metadata
```

### Adding a Tier 2 Script

1. Create `mainmenu/<category>/<tool-name>.sh` — use `platform.sh` for `pkg_install`/`pkg_remove`
2. Create `mainmenu/<category>/<tool-name>.meta.yaml`:

```yaml
name: "tool-name"
description: "What this script does"
type: install
root: true
order: 10
installed: false
check_command: "tool --version"
tags:
  - category
supported_os:
  - macos
  - kali
  - debian
  - ubuntu
```

3. Test: `bash <tool-name>.sh install` and `bash <tool-name>.sh uninstall`

## Supported Operating Systems

| OS Key | Tier 1 Filename | Package Manager |
|--------|-----------------|-----------------|
| `macos` | `macos.sh` | Homebrew |
| `kali` | `kali-linux.sh` | apt |
| `debian` | `debian.sh` | apt |
| `ubuntu` | `ubuntu.sh` | apt |

## Rules

1. **No YAML headers inside `.sh` files** — all metadata in `meta.yaml` or `.meta.yaml`
2. **Tier 1: no `if`/`case` for OS detection** — one file per OS
3. **Tier 1: always source `_common.sh`** at the top of every OS script
4. **Tier 2: always source `platform.sh`** for cross-platform package management
5. **Underscore-prefixed files** (`_common.sh`) are hidden from the menu
6. **Folder/file names**: lowercase, hyphenated (`nmap-tools-bundle`)
7. **Log everything** using `log_info`, `log_error`, `log_success` from `platform.sh`
8. **Use `mark_installed true/false`** after install/uninstall

## Cross-Referencing with Aliases

To show a script in multiple menu locations, add `aliases` to its metadata:

```yaml
# llm/mcp/mcp-obsidian/meta.yaml
aliases:
  - "editors/obsidian"
```

This makes the script appear under both `LLM → MCP` (its real location) and `Editors → Obsidian` (the alias target). The alias path is relative to `mainmenu/`. The script's actual files stay in one place — only display is duplicated.

## Checklist

- [ ] Metadata file (`meta.yaml` or `.meta.yaml`) with all required fields
- [ ] `supported_os` matches which OS scripts or platform support actually exist
- [ ] Script sources `platform.sh` (directly or via `_common.sh`)
- [ ] Tested install and uninstall on available OSes
- [ ] No inline YAML headers in `.sh` files
