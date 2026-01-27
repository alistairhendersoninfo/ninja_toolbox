# Kali Post-Setup - Technical Manual

## Architecture

Post-setup scripts handle initial configuration of a fresh Kali installation. Scripts are designed to be idempotent where possible.

## Scripts Reference

### nodejs.sh

**Purpose:** Install Node.js 20.x LTS

**Installation method:** NodeSource repository
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Check:** `node --version`

### fix-zsh.sh

**Purpose:** Fix ZSH undercover mode syntax errors

**Problem:** Lines in `.zshrc` like `: undercover &&` cause parsing errors

**Solution:** Comments out problematic lines
```bash
sed -i 's/^: undercover && /# : undercover \&\& /' "$HOME/.zshrc"
```

**Backup:** Creates `.zshrc.backup.YYYYMMDD_HHMMSS`

### proxmox-tools.sh

**Purpose:** Install Proxmox VM guest tools

**Installation:**
```bash
sudo apt-get install -y qemu-guest-agent
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent
```

**Note:** Requires QEMU Guest Agent enabled in Proxmox VM settings

### catppuccin-themes.sh

**Purpose:** Install Catppuccin color themes

**Components:**
- GTK theme
- Terminal theme
- ZSH theme integration

**Theme variants:** Mocha, Macchiato

### xrdp-xfce.sh

**Purpose:** Enable RDP access with XFCE desktop

**Installation:**
```bash
sudo apt-get install -y xrdp xfce4
echo "xfce4-session" > ~/.xsession
sudo systemctl enable xrdp
```

**Port:** 3389 (standard RDP)

## File Locations

- ZSH config: `~/.zshrc`
- ZSH backups: `~/.zshrc.backup.*`
- Themes: `~/.themes/`, `~/.local/share/themes/`

## Development

### Adding Post-Setup Scripts

1. Identify the configuration task
2. Make script idempotent (can run multiple times safely)
3. Create backups before modifying config files
4. Provide clear uninstall/restore function

## See Also

- [User Guide](../user_manuals/postsetup-kali.md)
