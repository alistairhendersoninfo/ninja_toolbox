# Kali Post-Setup - User Guide

## Overview

Post-installation scripts to configure a fresh Kali Linux system with essential tools and fixes.

## Available Tools

### Node.js

**What it does:** Installs Node.js 20.x LTS and npm.

**How to use:**
1. Run `ninjamenu` → PostsetupKali → Node.js
2. Node.js and npm will be available after installation

**Verify:**
```bash
node --version   # Should show v20.x
npm --version
```

### Fix ZSH Configuration

**What it does:** Fixes "closing brace expected" errors caused by undercover mode.

**How to use:**
1. Run `ninjamenu` → PostsetupKali → Fix ZSH Configuration
2. Restart terminal or run `source ~/.zshrc`

### Proxmox Tools

**What it does:** Installs qemu-guest-agent for Proxmox VM integration.

**How to use:**
1. Run `ninjamenu` → PostsetupKali → Proxmox Tools
2. Enable QEMU Guest Agent in Proxmox VM settings

### Catppuccin Themes

**What it does:** Installs Mocha and Macchiato themes for terminal and GTK.

**Themes available:**
- Catppuccin Mocha (dark)
- Catppuccin Macchiato (darker)

### XRDP with XFCE

**What it does:** Enables remote desktop access via RDP protocol.

**How to use:**
1. Run `ninjamenu` → PostsetupKali → XRDP with XFCE
2. Connect via RDP client to your Kali IP

## Common Tasks

### Fresh Kali Setup

Recommended order:
1. Fix ZSH Configuration
2. Node.js
3. Catppuccin Themes (optional)
4. XRDP if needed

## Troubleshooting

### ZSH still showing errors

**Solution:** Check if `.zshrc.backup.*` exists and restore if needed

### Node.js not in PATH

**Solution:** Restart terminal or run `source ~/.bashrc`

## See Also

- [Technical Manual](../technical_manuals/postsetup-kali.md)
