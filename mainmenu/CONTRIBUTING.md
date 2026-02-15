# Contributing Scripts to NinjaMenu

> **For LLMs, AI coding assistants, and developers.**
> Follow this guide exactly when creating or modifying scripts in the menu system.

## Architecture

NinjaMenu uses a **modular, OS-specific folder structure**. Each tool action has its own folder with separate scripts per operating system. There are no monolithic scripts with `if`/`case` OS detection -- one file per OS, always.

Full technical reference: [`.docs/technical_manuals/os-modular-architecture.md`](../.docs/technical_manuals/os-modular-architecture.md)

## Folder Structure

```
mainmenu/
└── <category>/
    └── <tool-group>/
        └── <tool>/
            ├── README.md
            ├── CONTRIBUTING.md
            └── <action>/
                ├── meta.yaml        # Metadata (name, description, order, supported OS)
                ├── _common.sh       # Shared functions (sourced by all OS scripts)
                ├── macos.sh         # macOS (brew)
                ├── ubuntu-22.04.sh  # Ubuntu 22.04 (apt)
                ├── ubuntu-24.04.sh  # Ubuntu 24.04 (apt)
                ├── debian.sh        # Debian (apt)
                ├── kali-linux.sh    # Kali Linux (apt)
                ├── fedora.sh        # Fedora (dnf)
                └── README.md
```

## Supported Operating Systems

| OS | Script Filename | Package Manager | Install Command |
|----|----------------|-----------------|-----------------|
| macOS | `macos.sh` | Homebrew | `brew install <pkg>` |
| Ubuntu 22.04 | `ubuntu-22.04.sh` | apt | `sudo apt install -y <pkg>` |
| Ubuntu 24.04 | `ubuntu-24.04.sh` | apt | `sudo apt install -y <pkg>` |
| Debian | `debian.sh` | apt | `sudo apt install -y <pkg>` |
| Kali Linux | `kali-linux.sh` | apt | `sudo apt install -y <pkg>` |
| Fedora | `fedora.sh` | dnf | `sudo dnf install -y <pkg>` |

## Adding a New Action

1. Create a folder: `mainmenu/<category>/<tool-group>/<tool>/<action-name>/`
2. Create `meta.yaml`:

```yaml
name: "Human Readable Name"
description: "What this action does"
version: "1.0.0"
author: "Author Name"
type: install
root: false
order: 10
check_command: "tool --version"
check_path: "/usr/bin/tool"
dependencies:
  - package1
tags:
  - category1
supported_os:
  - macos
  - ubuntu-22.04
  - ubuntu-24.04
```

3. Create `_common.sh`:

```bash
#!/bin/bash
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
    if command -v "$1" &>/dev/null; then return 0; fi
    return 1
}
```

4. Create OS scripts (e.g., `macos.sh`):

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

ACTION="${1:-install}"

case "$ACTION" in
    install)
        log_info "Installing <tool> on macOS..."
        brew install <pkg>
        log_ok "<tool> installed successfully"
        ;;
    uninstall)
        log_info "Uninstalling <tool> from macOS..."
        brew uninstall <pkg>
        log_ok "<tool> uninstalled successfully"
        ;;
    *)
        echo "Usage: $0 {install|uninstall}"
        exit 1
        ;;
esac
```

5. Update `supported_os` in `meta.yaml` to list only the OS scripts you created
6. Add a `README.md` for the action folder
7. Test: `bash <os>.sh install` and `bash <os>.sh uninstall`

## Adding OS Support to an Existing Action

1. Create the new OS script (e.g., `fedora.sh`) following the template above
2. Add the OS key to `supported_os` in `meta.yaml`
3. Implement install/uninstall using that OS's package manager
4. Source `_common.sh` at the top
5. Test both actions

## Rules

1. **No YAML headers inside `.sh` files** -- all metadata in `meta.yaml`
2. **No `if`/`case` for OS detection** -- one file per OS
3. **Always source `_common.sh`** at the top of every OS script
4. **Underscore-prefixed files** (`_common.sh`) are hidden from the menu
5. **Only create OS scripts you can test** -- update `supported_os` to match
6. **Folder names**: lowercase, hyphenated (`stealth-scan`)
7. **OS filenames**: exact match (`ubuntu-22.04.sh`, not `ubuntu.sh`)
8. **Log everything** using `log_info`, `log_error`, `log_ok`
9. **No monolithic scripts** -- if you're writing OS branches, split into files

## Checklist Per Action

- [ ] `meta.yaml` with all required fields
- [ ] `_common.sh` with shared functions
- [ ] `macos.sh`
- [ ] `ubuntu-22.04.sh`
- [ ] `ubuntu-24.04.sh`
- [ ] `debian.sh`
- [ ] `kali-linux.sh`
- [ ] `fedora.sh`
- [ ] `README.md`
- [ ] `supported_os` matches which scripts exist
- [ ] Tested install and uninstall on available OSes
