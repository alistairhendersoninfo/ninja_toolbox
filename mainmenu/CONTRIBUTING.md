# Contributing Scripts to NinjaMenu

> **For LLMs, AI coding assistants, and developers.**
> Follow this guide exactly when creating or modifying scripts in the menu system.

## Architecture

NinjaMenu uses a **three-tier metadata system**. Every script has externalised metadata (YAML) and uses the cross-platform `platform.sh` library. Scripts that need different code per OS use modular folders (Tier 1); OS-agnostic scripts use a simpler sibling metadata file (Tier 2).

Full technical reference: [`.docs/technical_manuals/os-modular-architecture.md`](../.docs/technical_manuals/os-modular-architecture.md)

## Placement Rule

**Scripts must always go inside a category subfolder** — never directly under a top-level menu folder. Top-level folders (e.g. `mainmenu/llm/`) should only contain category subfolders (`cli/`, `ide/`, `ai-tools/`, etc.), not loose scripts or script folders. If no suitable category exists, create one first.

A folder is either a **category** (contains only subfolders) or a **leaf** (contains only scripts) — never both.

### Category Metadata (`category.yaml`)

Submenu folders can include an optional `category.yaml` to set a display name and description shown in the menu:

```yaml
name: "CLI Tools"
description: "Command-line LLM interfaces and chatbots"
```

Both fields are optional. Without `category.yaml`, the folder name is titlecased (e.g. `cli` → `Cli`) and no description is shown.

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

## Menu Cache

The menu system uses an SQLite cache (`.cache/menu.db`) built from YAML metadata files. The cache auto-rebuilds when metadata file mtimes change, but you can force a rebuild:

```bash
# Force rebuild cache
./menu.py --rebuild

# Rebuild and check all installed statuses
.claude/scripts/ninja-rebuild.sh --check-installed
```

YAML metadata files are the single source of truth. The cache is a derived, disposable artifact. If the cache is deleted, it auto-rebuilds on next `menu.py` launch.

## Documentation

Every new script or folder **must** have accompanying documentation. Templates are provided — copy and fill in the placeholders.

### Required Docs

| Doc | Location | Template |
|-----|----------|----------|
| **Folder README** | `mainmenu/<category>/README.md` | `.docs/templates/folder_readme_template.md` |
| **User Manual** | `.docs/user_manuals/<folder>.md` | `.docs/templates/user_doc_template.md` |
| **Technical Manual** | `.docs/technical_manuals/<folder>.md` | `.docs/templates/technical_doc_template.md` |

### Folder README

Every menu folder must have a `README.md` (shown on GitHub). It should:

- Describe what the category covers
- List all scripts in a table (name, description, type)
- Link to the user guide and technical manual

```bash
cp .docs/templates/folder_readme_template.md mainmenu/<category>/README.md
```

### User Manual

End-user documentation explaining how to use each tool, common tasks, and troubleshooting.

```bash
cp .docs/templates/user_doc_template.md .docs/user_manuals/<folder>.md
```

### Technical Manual

Developer documentation covering architecture, script details, dependencies, integration points, and security considerations.

```bash
cp .docs/templates/technical_doc_template.md .docs/technical_manuals/<folder>.md
```

### Linking

The folder `README.md` must link to both manuals:

```markdown
- [User Guide](../../.docs/user_manuals/<folder>.md)
- [Technical Manual](../../.docs/technical_manuals/<folder>.md)
```

## Checklist

- [ ] Metadata file (`meta.yaml` or `.meta.yaml`) with all required fields
- [ ] `supported_os` matches which OS scripts or platform support actually exist
- [ ] Script sources `platform.sh` (directly or via `_common.sh`)
- [ ] Tested install and uninstall on available OSes
- [ ] No inline YAML headers in `.sh` files
- [ ] Cache rebuilds correctly (`./menu.py --rebuild`)
- [ ] Folder has `README.md` (from `folder_readme_template.md`)
- [ ] User manual exists in `.docs/user_manuals/`
- [ ] Technical manual exists in `.docs/technical_manuals/`
- [ ] `README.md` links to both manuals
