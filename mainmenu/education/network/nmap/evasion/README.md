# Nmap Evasion Scripts

Firewall and IDS evasion techniques using Nmap. All scripts in this folder require root privileges.

## Scripts

| Script | Description | Root |
|--------|-------------|------|
| `decoy-scan.sh` | Spoof multiple source IPs to mask the real scanner | Yes |
| `fragment-scan.sh` | Split packets into fragments to bypass firewalls | Yes |
| `idle-scan.sh` | Use a zombie host to scan without revealing your IP | Yes |
| `slow-scan.sh` | Paranoid/sneaky timing to evade IDS detection | Yes |

## Quick Start

```bash
ninjamenu
# Navigate to: Education -> Network -> Nmap -> Evasion
```

## Requirements

- `nmap` must be installed (install from **NinjaMenu > Network > nmap**)
- All scripts require root privileges

## Tags

`education` `nmap` `evasion` `firewall` `ids` `stealth` `security`
