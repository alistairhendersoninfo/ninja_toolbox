# Nmap Education Scripts

Educational and demonstration scripts for [Nmap](https://nmap.org) — the network mapper.

All scripts require `nmap` to be installed (`binary: "nmap"` in YAML header). Install it from **NinjaMenu > Network > nmap** first.

## Scripts

### Scanning

| Script | Description | Root |
|--------|-------------|------|
| `ping-sweep.sh` | Discover live hosts on a subnet (`nmap -sn`) | No |
| `quick-scan.sh` | Scan top 100 ports fast (`nmap -F`) | No |
| `full-port-scan.sh` | Scan all 65535 TCP ports (`nmap -p-`) | No |
| `stealth-syn-scan.sh` | Half-open SYN scan (`nmap -sS`) | Yes |
| `udp-scan.sh` | Top 100 UDP ports (`nmap -sU`) | Yes |
| `specific-ports.sh` | User-specified ports (`nmap -p`) | No |

### Footprinting

| Script | Description | Root |
|--------|-------------|------|
| `os-detection.sh` | OS fingerprinting (`nmap -O`) | Yes |
| `service-version.sh` | Service/version detection (`nmap -sV`) | No |
| `aggressive-scan.sh` | Full enumeration (`nmap -A`) | Yes |
| `traceroute.sh` | Network path mapping (`nmap --traceroute`) | Yes |

### Vulnerability

| Script | Description | Root |
|--------|-------------|------|
| `vuln-scan.sh` | NSE vulnerability scripts (`--script vuln`) | No |
| `ssl-audit.sh` | TLS/SSL cipher check (`--script ssl-enum-ciphers`) | No |
| `http-enum.sh` | Web server enumeration (`--script http-enum`) | No |

### Evasion

| Script | Description | Root |
|--------|-------------|------|
| `fragment-scan.sh` | Packet fragmentation (`nmap -f`) | Yes |
| `decoy-scan.sh` | Spoof source IPs (`nmap -D RND:5`) | Yes |
| `idle-scan.sh` | Zombie host scan (`nmap -sI`) | Yes |
| `slow-scan.sh` | Low-and-slow timing (`nmap -T1`) | Yes |

### Output

| Script | Description | Root |
|--------|-------------|------|
| `save-all-formats.sh` | Save XML + grepable + normal (`nmap -oA`) | No |
| `xml-output.sh` | XML output for tool parsing (`nmap -oX`) | No |
| `diff-scans.sh` | Compare two scans with ndiff | No |

### Discovery

| Script | Description | Root |
|--------|-------------|------|
| `dns-brute.sh` | DNS subdomain brute-force (`--script dns-brute`) | No |
| `smb-enum.sh` | SMB shares and users (`--script smb-enum-*`) | No |
| `snmp-enum.sh` | SNMP community strings (`--script snmp-brute`) | No |
| `broadcast-discovery.sh` | Discover hosts via broadcast (`--script broadcast-ping`) | Yes |

## Adding a Script

1. Copy `.docs/templates/tool_template.sh` into the appropriate technique folder
2. Set `binary: "nmap"` and `type: tool` in the YAML header
3. Write your nmap command(s) in the `run()` function

See [CONTRIBUTING.md](../../../../CONTRIBUTING.md) for full details.
