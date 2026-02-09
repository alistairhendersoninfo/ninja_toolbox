---
layout: page
title: Contribute
nav_order: 4
description: "How and why to contribute to NinjaMenu."
permalink: /contribute/
---

<img src="{{ '/assets/images/little_tracey_ninja_14213d.png' | relative_url }}" alt="Little Tracey Ninja" style="float: right; width: 140px; margin-left: 1rem;" />

# Contribute to NinjaMenu

## Why Contribute?

Every script you add helps everyone who sets up a system. Your 15-minute contribution saves hours across the community. Education scripts teach real skills. And every contribution is visible on your GitHub profile.

## What We Need

### Scripts (Easiest Way to Start)

Missing a tool you use daily? Write a script for it. Drop a `.sh` file in the right folder with a YAML header and it appears in the menu automatically.

Average time: **15 minutes** for a simple install script.

### Education Content

The `education/` section is new and needs scripts that demonstrate how to **use** tools, not just install them. Examples:
- "Quick Network Scan with nmap" -- walks through host discovery
- "Packet Capture Basics with tcpdump" -- demonstrates common capture filters
- "System Profiling with htop" -- explains what each metric means

### Documentation

Improve existing user or technical manuals. Add troubleshooting tips from your own experience. Fix typos. Every bit helps.

### Testing

Try NinjaMenu on different distros and report what works (or breaks). macOS testing is especially valuable.

## How to Contribute

1. **Fork** the repository
2. **Create a branch**: `git checkout -b add-mytool`
3. **Add your script** using the template below
4. **Test** that `ninjamenu --list` shows your script
5. **Open a PR** against `main`

For complete developer guidelines, see the [Contributing Guide](https://github.com/alistairhendersoninfo/ninja_toolbox/blob/main/CONTRIBUTING.md).

## Script Template

Copy this and fill in the blanks:

```bash
#!/bin/bash
# ---
# name: "My Tool"
# description: "What it does in one line"
# type: install
# root: true
# order: 20
# check_command: "mytool --version"
# tags: "category, keyword"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install mytool
    log_success "mytool installed!"
else
    require_root
    pkg_remove mytool
fi
```

## Where to Put Your Script

| Category | Folder | Examples |
|----------|--------|----------|
| System monitoring | `mainmenu/monitoring/` | htop, btop, glances |
| Network tools | `mainmenu/network/` | nmap, wireshark, tcpdump |
| AI/LLM tools | `mainmenu/llm/` | Claude, Gemini, Cursor |
| Git setup | `mainmenu/git/` | SSH keys, credentials |
| Kali post-setup | `mainmenu/postsetup-kali/` | Node.js, themes, shell fixes |
| Proxmox | `mainmenu/proxmox/` | VM management |
| Education | `mainmenu/education/` | Tool usage demos |

Need a new category? Create a folder under `mainmenu/` with a `README.md`.

## Recognition

All contributors are recognised in the project. Your scripts carry your name in the YAML `author:` field and appear in the Git history.
