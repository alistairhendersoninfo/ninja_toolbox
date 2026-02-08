# macOS Install Support — Development Notes

## PR: feature/macos-install-support

### What this adds
Cross-platform support for `install_menu.sh` so the menu system works on both macOS (Intel + Apple Silicon) and Linux (Kali/Ubuntu/Debian).

### Files to modify
- `install_menu.sh` — OS detection, Homebrew support, path fixes
- `.app/menu.py` — Apple Silicon path
- `README.md` — macOS in requirements and quick start
- `CONTRIBUTING.md` — cross-platform note

### Key changes
| Section | Linux (unchanged) | macOS (new) |
|---------|-------------------|-------------|
| Root check | Require sudo | Block sudo (Homebrew) |
| Packages | apt-get | brew install |
| Gum | Charm APT repo | brew install gum |
| Home dir | getent passwd | eval echo ~$USER |
| Group | $USER:$USER | $USER:staff |
| Bin path | /usr/bin | /opt/homebrew/bin or /usr/local/bin |
| sed -i | GNU sed | BSD sed (needs -i '') |

### Acceptance criteria
- [ ] `./install_menu.sh` works on macOS without sudo
- [ ] `ninjamenu` command works after install
- [ ] `ninjamenu --list` discovers scripts
- [ ] Linux path unchanged (no regressions)
