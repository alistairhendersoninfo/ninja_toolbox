---
layout: default
title: Script Architecture
parent: Documentation
nav_order: 5
---

<div style="float: right; margin-left: 1rem; text-align: center;">
  <img src="{{ '/assets/images/it_super_nerd_14213d.png' | relative_url }}" alt="IT Super Nerd" style="width: 110px; border-radius: 8px;" />
</div>

# Script Architecture

## How Scripts are Organised

NinjaMenu uses a **modular, OS-specific structure**. Instead of one large script full of `if`/`case` blocks to handle different operating systems, each OS gets its own dedicated script file. The right one is selected automatically when you install the menu.

## The Structure

Every tool action lives in its own folder:

```
mainmenu/
└── education/
    └── network/
        └── nmap/
            └── scanning/
                ├── meta.yaml          # What this action is (name, description, tags)
                ├── _common.sh         # Shared logic used by all OS scripts
                ├── macos.sh           # macOS version (uses brew)
                ├── ubuntu-22.04.sh    # Ubuntu 22.04 version (uses apt)
                ├── ubuntu-24.04.sh    # Ubuntu 24.04 version (uses apt)
                ├── debian.sh          # Debian version (uses apt)
                ├── kali-linux.sh      # Kali Linux version (uses apt)
                └── fedora.sh          # Fedora version (uses dnf)
```

## Supported Operating Systems

| OS | Package Manager | Priority |
|----|-----------------|----------|
| **macOS** | Homebrew (`brew`) | Primary |
| **Ubuntu 22.04** | apt | Primary |
| **Ubuntu 24.04** | apt | Primary |
| **Debian** | apt | Secondary |
| **Kali Linux** | apt | Secondary |
| **Fedora** | dnf | Secondary |

## How It Works

### Install Time (Not Runtime)

When you run `install_menu.sh`, the system:

1. **Detects your OS** -- identifies exactly what you're running
2. **Picks the right scripts** -- selects the matching OS file from each action folder
3. **Builds your menu** -- generates a `.active_menu/` directory containing only your OS's scripts
4. **Launches the menu** -- `menu.py` reads from the generated menu, not the source folders

This means the menu only contains scripts that work on your machine. No broken scripts, no unsupported tools cluttering the list.

### What Each File Does

| File | Purpose |
|------|---------|
| `meta.yaml` | Defines the action's name, description, sort order, tags, and which OSes are supported. Single source of truth -- no metadata duplicated in scripts. |
| `_common.sh` | Shared functions (logging, checks, variables) that every OS script sources. The underscore prefix hides it from the menu. |
| `macos.sh`, `ubuntu-22.04.sh`, etc. | The actual install/uninstall logic, using that OS's native package manager. Clean, focused, no OS detection needed. |

## meta.yaml Example

```yaml
name: "Stealth Scan"
description: "Run nmap with stealth scanning options"
version: "1.0.0"
author: "NinjaMenu"
type: install
root: true
order: 10
check_command: "nmap --version"
dependencies:
  - nmap
tags:
  - network
  - scanning
supported_os:
  - macos
  - ubuntu-22.04
  - ubuntu-24.04
  - kali-linux
```

The `supported_os` list tells the installer which OS scripts exist. If your OS isn't listed, the action won't appear in your menu.

## Contributing Scripts

Want to add a new tool or action? See the full technical guide:

- **Technical Manual:** [OS-Modular Architecture](https://github.com/alistairhendersoninfo/ninja_toolbox/blob/main/.docs/technical_manuals/os-modular-architecture.md) -- complete templates, naming conventions, and step-by-step instructions for LLMs and developers.

### Quick Steps

1. Create an action folder under the right tool
2. Add `meta.yaml` with the action's metadata
3. Add `_common.sh` with shared functions
4. Create one `.sh` file per OS you're supporting
5. Only list the OSes you've actually created in `supported_os`
6. Test with `bash <os>.sh install` and `bash <os>.sh uninstall`

### Naming Rules

- **Folders:** lowercase, hyphenated (`stealth-scan`, not `StealthScan`)
- **OS scripts:** exact match to the OS key (`ubuntu-22.04.sh`, not `ubuntu.sh`)
- **Shared logic:** always `_common.sh` (underscore prefix = hidden from menu)
