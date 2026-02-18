# nmap-tools-bundle - Development Notes

## PR: feature/network-nmap-tools-bundle

### What this adds
Bundle installer that installs Nmap, Zenmap GUI, and nmapUnleashed in one go.
Supports both Debian-based Linux (Kali, Ubuntu) and macOS (via Homebrew).

### Tools included
| Tool | Purpose | Verify with |
|------|---------|-------------|
| Nmap | Port scanner and network discovery | `nmap --version` |
| Zenmap | GUI front-end for Nmap | `zenmap --version` |
| nmapUnleashed | Automated scanning and reporting wrapper | `nu --help` |

### Acceptance criteria
- [ ] Installs all three tools on Ubuntu/Kali
- [ ] Installs all three tools on macOS
- [ ] Uninstall removes all three cleanly
- [ ] YAML header is complete and menu discovers the script
- [ ] Logging works and writes to `.docs/logs/`
- [ ] check_command detects installed state correctly

### Notes
- nmapUnleashed is installed via pipx from GitHub, requires `xsltproc` dependency
- macOS uses Homebrew (`brew install` / `brew install --cask`)
- Zenmap may not be in PATH on macOS (installed as .app)
- Users need to open a new terminal after install for pipx PATH changes
