# Proxmox Tools - Technical Manual

## Architecture

Proxmox scripts are designed to run on Proxmox VE hosts. They detect if running in a VM and warn the user.

## Detection Logic

```bash
if [[ ! -f /etc/pve/local/pve-ssl.pem ]] && [[ ! -d /etc/pve ]]; then
    # Not a Proxmox host - warn user
fi
```

## Scripts Reference

### proxmenux.sh

**Purpose:** Install ProxMenux management tool

**Source:** https://github.com/MacRimi/ProxMenux

**Installation:**
```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/MacRimi/ProxMenux/main/install_proxmenux.sh)"
```

**Check command:** `proxmenux --help`
**Check path:** `/usr/local/bin/proxmenux`

**Uninstall:**
```bash
rm -f /usr/local/bin/proxmenux
rm -rf /root/.proxmenux
rm -rf /var/lib/proxmenux
```

### proxmox-toolbox.sh

**Purpose:** First-time Proxmox configuration

**Source:** https://github.com/Tontonjo/proxmox_toolbox

**Installation:**
```bash
wget -qO proxmox_toolbox.sh https://raw.githubusercontent.com/Tontonjo/proxmox_toolbox/main/proxmox_toolbox.sh
bash proxmox_toolbox.sh
```

**Installs:**
- ifupdown2
- git, sudo
- libsasl2-modules
- amd64-microcode (optional)
- fail2ban (optional)

### pve-helper-scripts.sh

**Purpose:** Community PVE helper scripts

**Source:** https://github.com/community-scripts/ProxmoxVE

**Installation:**
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/pve-scripts-local.sh)"
```

**Uninstall:**
```bash
rm -rf /usr/local/share/pve-scripts
rm -f /usr/local/bin/pve-scripts
```

## Security Considerations

- All scripts require root access
- Scripts download and execute from remote sources
- Verify URLs before running in production

## Development

### Adding Proxmox Scripts

1. Add Proxmox detection check
2. Warn if not running on PVE host
3. Allow user to continue anyway (for testing)
4. Document source repository

## See Also

- [User Guide](../user_manuals/proxmox.md)
- [Community Scripts](https://community-scripts.github.io/ProxmoxVE/)
