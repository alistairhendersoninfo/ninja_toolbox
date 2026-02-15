# OS-Modular Script Architecture

> **Audience:** LLMs, AI coding assistants, and developers contributing scripts to NinjaMenu.
> This document is the single source of truth for how scripts are structured, named, and organised.

## Overview

NinjaMenu uses a **modular, OS-specific folder structure**. Each tool action has its own folder containing a shared metadata file, shared logic, and one script per supported operating system. The correct script is selected **at install time** based on the detected OS — there are no `if`/`case` blocks for OS detection inside scripts.

## Folder Structure

```
mainmenu/
└── <category>/                      # e.g., education, llm, postsetup-kali
    └── <tool-group>/                # e.g., network, cli, ide
        └── <tool>/                  # e.g., nmap, nmap-unleashed
            ├── README.md            # Tool-level docs (what the user sees)
            ├── CONTRIBUTING.md      # LLM/developer guide for this tool
            └── <action>/            # e.g., scanning, reporting, discovery
                ├── meta.yaml        # Metadata — name, description, order, tags, supported OS
                ├── _common.sh       # Shared functions sourced by all OS scripts
                ├── macos.sh         # macOS implementation (brew)
                ├── ubuntu-22.04.sh  # Ubuntu 22.04 implementation (apt)
                ├── ubuntu-24.04.sh  # Ubuntu 24.04 implementation (apt)
                ├── debian.sh        # Debian implementation (apt)
                ├── kali-linux.sh    # Kali Linux implementation (apt)
                ├── fedora.sh        # Fedora implementation (dnf)
                └── README.md        # Action-level docs
```

## Supported Operating Systems

| OS | Script Filename | Package Manager | Install Command | Priority |
|----|----------------|-----------------|-----------------|----------|
| macOS | `macos.sh` | Homebrew | `brew install <pkg>` | Primary |
| Ubuntu 22.04 | `ubuntu-22.04.sh` | apt | `sudo apt install -y <pkg>` | Primary |
| Ubuntu 24.04 | `ubuntu-24.04.sh` | apt | `sudo apt install -y <pkg>` | Primary |
| Debian | `debian.sh` | apt | `sudo apt install -y <pkg>` | Secondary |
| Kali Linux | `kali-linux.sh` | apt | `sudo apt install -y <pkg>` | Secondary |
| Fedora | `fedora.sh` | dnf | `sudo dnf install -y <pkg>` | Secondary |

## meta.yaml Format

Every action folder **must** have a `meta.yaml`. This is the single source of truth for metadata — do NOT put YAML headers inside `.sh` files.

```yaml
name: "Human Readable Name"
description: "What this action does"
version: "1.0.0"
author: "Author Name"
type: install              # install (Install/Uninstall) or config (Run only)
root: false                # true if needs sudo
order: 10                  # Sort order in menu (lower = higher)
hidden: false
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
  - ubuntu-22.04
  - ubuntu-24.04
  - debian
  - kali-linux
  - fedora
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
| check_command | string | No | Command to verify installation (e.g., `nmap --version`) |
| check_path | string | No | Path to check existence (e.g., `/usr/bin/nmap`) |
| dependencies | array | No | Required system packages |
| tags | array | No | Categorisation tags |
| supported_os | array | Yes | Which OS scripts exist in this folder |

## _common.sh Template

Shared logic sourced by every OS script. Underscore prefix hides it from the menu.

```bash
#!/bin/bash
# Shared functions for this action — sourced by all OS scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"
LOG_DIR="${MENU_ROOT}/.docs/logs"
SCRIPT_NAME="$(basename "${SCRIPT_DIR}")"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$LOG_DIR"

log_info()  { echo "[INFO]  $(date '+%H:%M:%S') $*" | tee -a "$LOG_FILE"; }
log_error() { echo "[ERROR] $(date '+%H:%M:%S') $*" | tee -a "$LOG_FILE" >&2; }
log_ok()    { echo "[OK]    $(date '+%H:%M:%S') $*" | tee -a "$LOG_FILE"; }

check_installed() {
    if command -v "$1" &>/dev/null; then
        return 0
    fi
    return 1
}
```

## OS Script Template

Each OS-specific script follows this exact pattern:

```bash
#!/bin/bash
# OS-specific implementation — do NOT add YAML headers here (use meta.yaml)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

ACTION="${1:-install}"

case "$ACTION" in
    install)
        log_info "Installing <tool> on <os>..."
        # Use this OS's package manager:
        #   macOS:                brew install <pkg>
        #   Ubuntu/Debian/Kali:   sudo apt install -y <pkg>
        #   Fedora:               sudo dnf install -y <pkg>
        log_ok "<tool> installed successfully"
        ;;
    uninstall)
        log_info "Uninstalling <tool> on <os>..."
        # Reverse the install
        log_ok "<tool> uninstalled successfully"
        ;;
    *)
        echo "Usage: $0 {install|uninstall}"
        exit 1
        ;;
esac
```

## How the Menu is Generated (Install-Time)

The menu is **pre-baked at install time**, not resolved at runtime:

```
install_menu.sh runs
    │
    ├── Detects the OS (e.g., macOS 14 Sonoma)
    │
    ├── For each action folder:
    │   ├── Looks for the matching OS script (e.g., macos.sh)
    │   ├── Reads _common.sh to bundle shared logic
    │   └── Reads meta.yaml for menu metadata
    │
    ├── Generates .active_menu/
    │   └── Fully resolved, single-file scripts for this OS only
    │       Each script has the YAML header (from meta.yaml) baked in
    │
    └── menu.py reads from .active_menu/ (not mainmenu/ directly)
```

The `.active_menu/` directory is gitignored — it only exists on the installed machine.

## Rules (Must Follow)

1. **No YAML headers inside `.sh` files** — all metadata lives in `meta.yaml`
2. **No `if`/`case` blocks for OS detection** — one file per OS, always
3. **Always source `_common.sh`** at the top of every OS script
4. **Underscore-prefixed files** (`_common.sh`) are hidden from the menu
5. **Only create OS scripts you can test** — update `supported_os` in `meta.yaml` to match
6. **Folder names**: lowercase, hyphenated (e.g., `stealth-scan`)
7. **OS script filenames**: must exactly match the table above (e.g., `ubuntu-22.04.sh`, not `ubuntu.sh`)
8. **One action per folder** — do not combine multiple tools into one folder
9. **Log everything** — use `log_info`, `log_error`, `log_ok` from `_common.sh`
10. **No monolithic scripts** — if you find yourself writing OS-specific branches, split into separate files

## Adding a New Action (Step by Step)

1. Create a folder under the appropriate tool: `mainmenu/<category>/<tool-group>/<tool>/<action-name>/`
2. Create `meta.yaml` using the format above
3. Create `_common.sh` with shared functions
4. Create one `.sh` file per OS you're implementing (e.g., `macos.sh`, `ubuntu-22.04.sh`)
5. List only the OS scripts you created in `supported_os` in `meta.yaml`
6. Add a `README.md` describing what the action does
7. Test: `bash <os>.sh install` and `bash <os>.sh uninstall`

## Adding a New OS to an Existing Action

1. Create the new OS script (e.g., `fedora.sh`) using the OS script template
2. Add the OS key to `supported_os` in `meta.yaml`
3. Implement the install/uninstall logic using that OS's package manager
4. Source `_common.sh` at the top
5. Test both install and uninstall

## Checklist Per Action

- [ ] `meta.yaml` created with all required fields
- [ ] `_common.sh` created with shared functions
- [ ] `macos.sh`
- [ ] `ubuntu-22.04.sh`
- [ ] `ubuntu-24.04.sh`
- [ ] `debian.sh`
- [ ] `kali-linux.sh`
- [ ] `fedora.sh`
- [ ] `README.md` for the action folder
- [ ] `supported_os` in `meta.yaml` matches which scripts actually exist
- [ ] All scripts tested with `install` and `uninstall` actions
