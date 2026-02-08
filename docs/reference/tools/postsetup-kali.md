---
layout: default
title: Post-Setup Kali
parent: Tool Reference
grand_parent: Documentation
nav_order: 5
---

# Post-Setup Kali

Post-installation scripts to configure a fresh Kali Linux system with essential tools and fixes.

**Location:** [`mainmenu/postsetup-kali/`](https://github.com/alistairhendersoninfo/ninja_toolbox/tree/main/mainmenu/postsetup-kali)

## Available Scripts

| Script | Description | Check Command |
|--------|-------------|---------------|
| Node.js | Install Node.js 20.x LTS and npm | `node --version` |
| Fix ZSH Configuration | Fix undercover mode syntax errors in `.zshrc` | n/a (config) |
| Proxmox Tools | Install `qemu-guest-agent` for VM integration | `systemctl status qemu-guest-agent` |
| Catppuccin Themes | Install Mocha and Macchiato themes for terminal and GTK | n/a (config) |
| XRDP with XFCE | Enable remote desktop access via RDP | `systemctl status xrdp` |

## Recommended Order for Fresh Kali

1. **Fix ZSH Configuration** -- Fixes shell errors first
2. **Node.js** -- Required by LLM CLI tools
3. **Catppuccin Themes** -- Optional, cosmetic
4. **XRDP** -- Only if you need remote desktop
5. **Proxmox Tools** -- Only if running in a Proxmox VM

## Script Details

### Node.js

Installs Node.js 20.x LTS from the NodeSource repository:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Fix ZSH Configuration

Fixes "closing brace expected" errors caused by Kali's undercover mode. Comments out problematic lines and creates a timestamped backup of `.zshrc`.

### Proxmox Tools

Installs and enables `qemu-guest-agent`. After installation, enable "QEMU Guest Agent" in your Proxmox VM settings (Options tab).

### Catppuccin Themes

Installs two theme variants:
- **Mocha** -- Dark theme
- **Macchiato** -- Darker theme

Applies to GTK, terminal, and ZSH.

### XRDP with XFCE

Installs `xrdp` and configures it to use XFCE4 as the desktop session. Connect via any RDP client on port 3389.

## Technical Details

- All scripts are designed to be idempotent (safe to run multiple times)
- Config-modifying scripts create backups before making changes
- These scripts are Linux-only and use `require_linux` guards
