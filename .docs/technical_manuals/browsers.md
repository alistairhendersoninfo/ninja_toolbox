# Browsers - Technical Manual

## Architecture

Browser scripts are organized under a single submenu:
- `desktop/` - Full-featured desktop web browsers

All scripts are Tier 2 (sibling `.meta.yaml`). Chrome, Opera, and Brave follow the GPG key + apt repo pattern (similar to `databases/rabbitmq.sh`). Firefox uses the default distribution repositories.

## Scripts Reference

### desktop/google-chrome.sh

**Purpose:** Install Google Chrome (stable channel)

**Installation method:** GPG key + apt repository
```bash
# GPG key
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg

# Repo (amd64 only)
deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main
```

**Architecture guard:** Checks `dpkg --print-architecture` for amd64; exits with error on other architectures.

**Check:** `google-chrome --version`

**File locations:**
- GPG key: `/usr/share/keyrings/google-chrome.gpg`
- Repo: `/etc/apt/sources.list.d/google-chrome.list`

### desktop/opera.sh

**Purpose:** Install Opera Browser (stable channel)

**Installation method:** GPG key + apt repository
```bash
# GPG key
curl -fsSL https://deb.opera.com/archive.key | gpg --dearmor -o /usr/share/keyrings/opera-browser.gpg

# Repo
deb [signed-by=/usr/share/keyrings/opera-browser.gpg] https://deb.opera.com/opera-stable/ stable non-free
```

**Check:** `opera --version`

**File locations:**
- GPG key: `/usr/share/keyrings/opera-browser.gpg`
- Repo: `/etc/apt/sources.list.d/opera-stable.list`

### desktop/brave.sh

**Purpose:** Install Brave Browser

**Installation method:** Binary GPG key + apt repository
```bash
# GPG key (direct binary download, no dearmor needed)
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

# Repo
deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main
```

**Check:** `brave-browser --version`

**File locations:**
- GPG key: `/usr/share/keyrings/brave-browser-archive-keyring.gpg`
- Repo: `/etc/apt/sources.list.d/brave-browser-release.list`

### desktop/firefox.sh

**Purpose:** Install Firefox ESR

**Installation method:** Default distribution repositories (no GPG key or repo setup needed)
```bash
pkg_update
pkg_install firefox-esr
```

**Check:** `firefox-esr --version`

## Dependencies

- `curl`, `gnupg`, `apt-transport-https` — for Chrome, Opera, Brave (repo setup)
- No extra dependencies for Firefox ESR

## Security Notes

- All third-party repositories use GPG-signed packages via `/usr/share/keyrings/` (modern apt keyring approach)
- No keys are added to the global trusted keyring (`/etc/apt/trusted.gpg`)
- Uninstall scripts clean up both the repo file and GPG key

## Development

### Adding a New Browser

1. Copy `google-chrome.sh` and `google-chrome.meta.yaml` as templates
2. Update GPG key URL, repo URL, and package name
3. Set appropriate `check_command` in `.meta.yaml`
4. Update `order` field for menu positioning
5. Update README.md, user manual, and technical manual

## See Also

- [User Guide](../user_manuals/browsers.md)
