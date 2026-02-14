# Nmap Scanning Scripts

Core port scanning and host discovery techniques using Nmap.

## Scripts

| Script | Description | Root |
|--------|-------------|------|
| `ping-sweep.sh` | Discover live hosts on a subnet using ICMP ping | No |
| `quick-scan.sh` | Scan top 100 ports fast using `nmap -F` | No |
| `full-port-scan.sh` | Scan all 65535 TCP ports | No |
| `specific-ports.sh` | Scan user-specified ports | No |
| `stealth-syn-scan.sh` | Half-open SYN scan that doesn't complete TCP handshake | Yes |
| `udp-scan.sh` | Scan top 100 UDP ports for services like DNS, SNMP, DHCP | Yes |

## Quick Start

```bash
ninjamenu
# Navigate to: Education -> Network -> Nmap -> Scanning
```

## Requirements

- `nmap` must be installed (install from **NinjaMenu > Network > nmap**)
- `stealth-syn-scan.sh` and `udp-scan.sh` require root privileges

## Tags

`education` `nmap` `scanning` `ports` `tcp` `udp` `host-discovery`
