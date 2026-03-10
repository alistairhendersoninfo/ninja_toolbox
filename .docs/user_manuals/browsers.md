# Browsers - User Guide

## Overview

The Browsers menu provides installers for popular desktop web browsers on Debian-based systems. Each script handles GPG key setup, repository configuration, and package installation.

## Available Browsers

### Google Chrome

Google's fast, secure web browser. Available on amd64 architecture only.

**Installation:**
1. Run `ninjamenu` → Browsers → Desktop Browsers → Google Chrome
2. Launch from applications menu or run `google-chrome`

**Usage:**
```bash
google-chrome              # Launch browser
google-chrome --incognito  # Launch in incognito mode
```

### Opera

Feature-rich browser with built-in VPN, ad blocker, and sidebar messenger integrations.

**Installation:**
1. Run `ninjamenu` → Browsers → Desktop Browsers → Opera
2. Launch from applications menu or run `opera`

**Usage:**
```bash
opera            # Launch browser
opera --private  # Launch in private mode
```

### Brave

Privacy-focused browser built on Chromium with built-in ad and tracker blocking.

**Installation:**
1. Run `ninjamenu` → Browsers → Desktop Browsers → Brave
2. Launch from applications menu or run `brave-browser`

**Usage:**
```bash
brave-browser              # Launch browser
brave-browser --incognito  # Launch in private mode
```

### Firefox ESR

Mozilla's open-source browser, Extended Support Release for long-term stability.

**Installation:**
1. Run `ninjamenu` → Browsers → Desktop Browsers → Firefox ESR
2. Launch from applications menu or run `firefox-esr`

**Usage:**
```bash
firefox-esr              # Launch browser
firefox-esr --private    # Launch in private mode
```

## Prerequisites

- Root/sudo access
- Debian-based system (Kali, Debian, Ubuntu)
- Internet connection for downloading packages and GPG keys

## Troubleshooting

### Browser won't launch from terminal

**Solution:** Try launching with `--no-sandbox` flag (not recommended for regular use) or check if a display server is running.

### GPG key errors during install

**Solution:** The scripts handle GPG key import automatically. If you see errors, check your internet connection and retry.

### Google Chrome says "unsupported architecture"

**Solution:** Chrome only supports amd64 (x86_64). On ARM systems, use Firefox ESR or Brave (if available for your architecture).

## See Also

- [Technical Manual](../technical_manuals/browsers.md)
