---
layout: default
title: Proxmox
parent: Tool Reference
grand_parent: Documentation
nav_order: 6
---

# Proxmox Tools

Tools for Proxmox VE hypervisor management. These scripts are designed to run on the Proxmox host, not inside guest VMs.

**Location:** [`mainmenu/proxmox/`](https://github.com/alistairhendersoninfo/ninja_toolbox/tree/main/mainmenu/proxmox)

{: .warning }
These scripts must run on the Proxmox VE server itself. They detect if they're running inside a VM and will warn you.

## Available Scripts

| Script | Description | Source |
|--------|-------------|--------|
| ProxMenux | Interactive menu system for PVE management | [MacRimi/ProxMenux](https://github.com/MacRimi/ProxMenux) |
| Proxmox Toolbox | Quick first-time PVE configuration | [Tontonjo/proxmox_toolbox](https://github.com/Tontonjo/proxmox_toolbox) |
| PVE Helper Scripts | 400+ community Proxmox helper scripts | [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE) |

## ProxMenux

Interactive management tool providing:
- LXC container management
- VM templates
- System configuration

After installation, run `proxmenux` to launch.

## Proxmox Toolbox

First-time configuration that installs:
- `ifupdown2`, `git`, `sudo`, `libsasl2-modules`
- Optional: `amd64-microcode`
- Optional: `fail2ban` with SSH protection

## PVE Helper Scripts

Access to 400+ community scripts for:
- LXC container creation (Docker, Home Assistant, etc.)
- VM templates
- Backup solutions
- Monitoring tools

## Requirements

- Must run on Proxmox VE host (not inside a VM)
- Root access required
- All scripts use `require_linux` guards

## Technical Details

- Scripts download and execute from remote GitHub repositories
- Proxmox host detection checks for `/etc/pve/` directory and PVE SSL certificates
- All scripts require root access
- Uninstall removes downloaded binaries and configuration
