# Nmap Footprinting Scripts

OS detection, service enumeration, and host fingerprinting techniques using Nmap.

## Scripts

| Script | Description | Root |
|--------|-------------|------|
| `aggressive-scan.sh` | Full enumeration with OS detection, versions, scripts, and traceroute | Yes |
| `os-detection.sh` | OS fingerprinting using TCP/IP stack analysis | Yes |
| `service-version.sh` | Detect service versions running on open ports | No |
| `traceroute.sh` | Map the network path to a target host | Yes |

## Quick Start

```bash
ninjamenu
# Navigate to: Education -> Network -> Nmap -> Footprinting
```

## Requirements

- `nmap` must be installed (install from **NinjaMenu > Network > nmap**)
- Most scripts require root privileges for raw socket access

## Tags

`education` `nmap` `footprinting` `os-detection` `enumeration` `reconnaissance`
