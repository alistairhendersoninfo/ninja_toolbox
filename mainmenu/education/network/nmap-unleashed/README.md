# Nmap-Unleashed Education Scripts

Educational and demonstration scripts for [nmap-unleashed](https://github.com/Sharkeonix/nmap-unleashed) — an enhanced nmap wrapper with automated scanning and reporting.

All scripts require `nu` to be installed (`binary: "nu"` in YAML header). Install it from **NinjaMenu > Network > nmap-unleashed** first.

## Scripts

### Scanning

| Script | Description | Root |
|--------|-------------|------|
| `auto-scan.sh` | Automated scan with default profile | No |
| `report-scan.sh` | Scan with HTML/XML report output | No |
| `custom-profile.sh` | User-selected nmap-unleashed options | No |

### Reporting

| Script | Description | Root |
|--------|-------------|------|
| `html-report.sh` | Generate a formatted HTML scan report | No |
| `xml-export.sh` | Export scan results as XML for parsing | No |

## Adding a Script

1. Copy `.docs/templates/tool_template.sh` into the appropriate folder
2. Set `binary: "nu"` and `type: tool` in the YAML header
3. Write your nmap-unleashed command(s) in the `run()` function

See [CONTRIBUTING.md](../../../../CONTRIBUTING.md) for full details.
