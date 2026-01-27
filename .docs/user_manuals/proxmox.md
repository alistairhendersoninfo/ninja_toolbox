# Proxmox Tools - User Guide

## Overview

Tools for Proxmox VE hypervisor management. These scripts are designed to run on the Proxmox host, not inside guest VMs.

## Available Tools

### ProxMenux

**What it does:** Interactive menu system for Proxmox VE management.

**How to use:**
1. Run `ninjamenu` → Proxmox → ProxMenux
2. After installation, run `proxmenux` to launch

**Features:**
- LXC container management
- VM templates
- System configuration

### Proxmox Toolbox

**What it does:** Quick first-time Proxmox configuration.

**Installs:**
- ifupdown2, git, sudo, libsasl2-modules
- Optional: amd64-microcode
- Optional: fail2ban with SSH protection

**How to use:**
1. Run `ninjamenu` → Proxmox → Proxmox Toolbox
2. Follow interactive prompts

### PVE Helper Scripts

**What it does:** Access to 400+ community Proxmox helper scripts.

**How to use:**
1. Run `ninjamenu` → Proxmox → PVE Helper Scripts
2. Access via Proxmox web interface or CLI

**Popular scripts:**
- LXC container creation (Docker, Home Assistant, etc.)
- VM templates
- Backup solutions
- Monitoring tools

## Requirements

- Must run on Proxmox VE host
- Root access required
- Will warn if run inside a VM

## Troubleshooting

### "Not a Proxmox host" warning

**Cause:** Script detected it's running in a VM, not on PVE host

**Solution:** These scripts must run on the Proxmox server itself

## See Also

- [Technical Manual](../technical_manuals/proxmox.md)
- [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)
