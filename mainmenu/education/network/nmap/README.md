# Nmap Education Scripts

Educational and demonstration scripts for [Nmap](https://nmap.org) — the network mapper.

All scripts require `nmap` to be installed (`binary: "nmap"` in YAML header). Install it from **NinjaMenu > Network > nmap** first.

## Categories

| Folder | Purpose |
|--------|---------|
| `scanning/` | Host discovery, port scanning, scan types |
| `footprinting/` | OS detection, service enumeration, version probing |
| `vulnerability/` | NSE vulnerability scripts, CVE scanning |

## Adding a Script

1. Copy `.docs/templates/tool_template.sh` into the appropriate technique folder
2. Set `binary: "nmap"` and `type: tool` in the YAML header
3. Write your nmap command(s) in the `run()` function

See [CONTRIBUTING.md](../../../../CONTRIBUTING.md) for full details.
