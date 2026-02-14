# Education Scripts - Technical Manual

## Architecture

Education scripts are **tool scripts** (`type: tool`) that depend on binaries installed by the main toolbox categories. They are organised by **category > tool > technique**:

```
education/
└── network/
    ├── nmap/
    │   ├── scanning/        # 6 scripts — host discovery, port scanning
    │   ├── footprinting/    # 4 scripts — OS detection, service enum
    │   ├── vulnerability/   # 3 scripts — NSE vuln scanning
    │   ├── discovery/       # 4 scripts — DNS, SMB, SNMP, broadcast
    │   ├── evasion/         # 4 scripts — firewall/IDS bypass
    │   └── output/          # 3 scripts — export, diff, formatting
    └── nmap-unleashed/
        ├── scanning/        # 3 scripts — automated scan profiles
        └── reporting/       # 2 scripts — HTML/XML export
```

Each script declares `binary: "nmap"` or `binary: "nu"` in its YAML header. The menu system checks for the binary before allowing execution.

## Scripts Reference

### Nmap Scripts (24 total)

#### scanning/ping-sweep.sh
**Purpose:** Discover live hosts on a subnet using `nmap -sn`
**Location:** `mainmenu/education/network/nmap/scanning/ping-sweep.sh`
**Root:** No

#### scanning/quick-scan.sh
**Purpose:** Scan top 100 ports using `nmap -F`
**Location:** `mainmenu/education/network/nmap/scanning/quick-scan.sh`
**Root:** No

#### scanning/full-port-scan.sh
**Purpose:** Scan all 65535 TCP ports using `nmap -p-`
**Location:** `mainmenu/education/network/nmap/scanning/full-port-scan.sh`
**Root:** No

#### scanning/specific-ports.sh
**Purpose:** Scan user-specified ports using `nmap -p`
**Location:** `mainmenu/education/network/nmap/scanning/specific-ports.sh`
**Root:** No

#### scanning/stealth-syn-scan.sh
**Purpose:** Half-open SYN scan using `nmap -sS`
**Location:** `mainmenu/education/network/nmap/scanning/stealth-syn-scan.sh`
**Root:** Yes

#### scanning/udp-scan.sh
**Purpose:** Scan top 100 UDP ports using `nmap -sU`
**Location:** `mainmenu/education/network/nmap/scanning/udp-scan.sh`
**Root:** Yes

#### footprinting/os-detection.sh
**Purpose:** OS fingerprinting using `nmap -O`
**Location:** `mainmenu/education/network/nmap/footprinting/os-detection.sh`
**Root:** Yes

#### footprinting/service-version.sh
**Purpose:** Service/version detection using `nmap -sV`
**Location:** `mainmenu/education/network/nmap/footprinting/service-version.sh`
**Root:** No

#### footprinting/aggressive-scan.sh
**Purpose:** Full enumeration using `nmap -A`
**Location:** `mainmenu/education/network/nmap/footprinting/aggressive-scan.sh`
**Root:** Yes

#### footprinting/traceroute.sh
**Purpose:** Network path mapping using `nmap --traceroute`
**Location:** `mainmenu/education/network/nmap/footprinting/traceroute.sh`
**Root:** Yes

#### vulnerability/vuln-scan.sh
**Purpose:** NSE vulnerability scripts using `--script vuln`
**Location:** `mainmenu/education/network/nmap/vulnerability/vuln-scan.sh`
**Root:** No

#### vulnerability/ssl-audit.sh
**Purpose:** TLS/SSL cipher check using `--script ssl-enum-ciphers`
**Location:** `mainmenu/education/network/nmap/vulnerability/ssl-audit.sh`
**Root:** No

#### vulnerability/http-enum.sh
**Purpose:** Web server enumeration using `--script http-enum`
**Location:** `mainmenu/education/network/nmap/vulnerability/http-enum.sh`
**Root:** No

#### discovery/dns-brute.sh
**Purpose:** DNS subdomain brute-force using `--script dns-brute`
**Location:** `mainmenu/education/network/nmap/discovery/dns-brute.sh`
**Root:** No

#### discovery/smb-enum.sh
**Purpose:** SMB shares and users using `--script smb-enum-*`
**Location:** `mainmenu/education/network/nmap/discovery/smb-enum.sh`
**Root:** No

#### discovery/snmp-enum.sh
**Purpose:** SNMP community strings using `--script snmp-brute`
**Location:** `mainmenu/education/network/nmap/discovery/snmp-enum.sh`
**Root:** No

#### discovery/broadcast-discovery.sh
**Purpose:** Broadcast host discovery using `--script broadcast-ping`
**Location:** `mainmenu/education/network/nmap/discovery/broadcast-discovery.sh`
**Root:** Yes

#### evasion/fragment-scan.sh
**Purpose:** Packet fragmentation using `nmap -f`
**Location:** `mainmenu/education/network/nmap/evasion/fragment-scan.sh`
**Root:** Yes

#### evasion/decoy-scan.sh
**Purpose:** Spoof source IPs using `nmap -D RND:5`
**Location:** `mainmenu/education/network/nmap/evasion/decoy-scan.sh`
**Root:** Yes

#### evasion/idle-scan.sh
**Purpose:** Zombie host scan using `nmap -sI`
**Location:** `mainmenu/education/network/nmap/evasion/idle-scan.sh`
**Root:** Yes

#### evasion/slow-scan.sh
**Purpose:** Low-and-slow timing using `nmap -T1`
**Location:** `mainmenu/education/network/nmap/evasion/slow-scan.sh`
**Root:** Yes

#### output/save-all-formats.sh
**Purpose:** Save XML + grepable + normal using `nmap -oA`
**Location:** `mainmenu/education/network/nmap/output/save-all-formats.sh`
**Root:** No

#### output/xml-output.sh
**Purpose:** XML output for tool parsing using `nmap -oX`
**Location:** `mainmenu/education/network/nmap/output/xml-output.sh`
**Root:** No

#### output/diff-scans.sh
**Purpose:** Compare two scans with ndiff
**Location:** `mainmenu/education/network/nmap/output/diff-scans.sh`
**Root:** No

### Nmap-Unleashed Scripts (5 total)

#### scanning/auto-scan.sh
**Purpose:** Automated scan with default nmap-unleashed profile
**Location:** `mainmenu/education/network/nmap-unleashed/scanning/auto-scan.sh`
**Root:** No

#### scanning/custom-profile.sh
**Purpose:** User-selected nmap-unleashed scan options
**Location:** `mainmenu/education/network/nmap-unleashed/scanning/custom-profile.sh`
**Root:** No

#### scanning/report-scan.sh
**Purpose:** Scan with HTML/XML report output
**Location:** `mainmenu/education/network/nmap-unleashed/scanning/report-scan.sh`
**Root:** No

#### reporting/html-report.sh
**Purpose:** Generate formatted HTML scan report
**Location:** `mainmenu/education/network/nmap-unleashed/reporting/html-report.sh`
**Root:** No

#### reporting/xml-export.sh
**Purpose:** Export scan results as XML
**Location:** `mainmenu/education/network/nmap-unleashed/reporting/xml-export.sh`
**Root:** No

## Integration Points

### Binary Dependency Check

The menu system reads the `binary:` YAML field and runs `command -v <binary>` to check availability. Scripts are blocked if the binary is not found.

### Parent Tool Mapping

| Education Tool | Install From |
|---------------|-------------|
| nmap scripts | Network > nmap |
| nmap-unleashed scripts | Network > nmap-tools-bundle |

## Security Considerations

- Education scripts execute real tool commands against user-specified targets
- Scripts requiring root are marked with `root: true` and the menu prompts for sudo
- Users should only scan networks they own or have explicit authorisation to test
- Evasion scripts are for educational purposes on controlled environments only

## Development

### Adding a New Education Script

1. Copy template: `cp .docs/templates/tool_template.sh mainmenu/education/{category}/{tool}/{technique}/name.sh`
2. Set `binary:` to the required command name
3. Set `type: tool` in the YAML header
4. Write tool commands in the `run()` function
5. Update the technique folder's README.md
6. Update the parent tool's README.md script table

### Testing

```bash
# Test individual script
bash mainmenu/education/network/nmap/scanning/quick-scan.sh

# Verify in menu
ninjamenu --submenu education
```

## Changelog

- **v1.0.0** - Initial implementation with nmap and nmap-unleashed scripts

## See Also

- [User Guide](../user_manuals/education.md)
- [Network Tools Technical Manual](./network.md)
