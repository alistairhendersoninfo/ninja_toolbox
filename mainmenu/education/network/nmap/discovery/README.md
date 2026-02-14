# Nmap Discovery Scripts

Network and service discovery techniques using Nmap NSE scripts.

## Scripts

| Script | Description | Root |
|--------|-------------|------|
| `broadcast-discovery.sh` | Find hosts on the local network via broadcast protocols | Yes |
| `dns-brute.sh` | Enumerate subdomains via DNS brute-force | No |
| `smb-enum.sh` | Discover SMB shares, users, and OS info | No |
| `snmp-enum.sh` | Discover SNMP community strings and device info | No |

## Quick Start

```bash
ninjamenu
# Navigate to: Education -> Network -> Nmap -> Discovery
```

## Requirements

- `nmap` must be installed (install from **NinjaMenu > Network > nmap**)
- `broadcast-discovery.sh` requires root privileges

## Tags

`education` `nmap` `discovery` `dns` `smb` `snmp` `network`
