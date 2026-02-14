# Education Scripts - User Guide

## Overview

The Education category contains **tool scripts** — educational demonstrations and automation scripts that use tools already installed via the NinjaMenu toolbox. These scripts teach you how to use security and network tools through guided, repeatable examples.

## How It Works

Each script declares a `binary:` field in its YAML header. The menu checks whether that binary is installed:

- **Ready** = Binary found, script can run
- **Blocked** = Binary not found — install the tool first from its parent category

## Available Tools

### Nmap

Network mapper scripts covering six technique areas:

**Scanning** — Core port scanning and host discovery
- Ping sweep, quick scan, full port scan, stealth SYN, UDP scan, specific ports

**Footprinting** — OS detection and service enumeration
- OS fingerprinting, service version detection, aggressive scan, traceroute

**Vulnerability** — Security auditing with NSE scripts
- Vulnerability scan, SSL/TLS audit, HTTP enumeration

**Discovery** — Network and service discovery
- DNS brute-force, SMB enumeration, SNMP enumeration, broadcast discovery

**Evasion** — Firewall and IDS bypass techniques
- Packet fragmentation, decoy scan, idle/zombie scan, slow timing

**Output** — Scan result formatting and comparison
- Save all formats, XML export, scan diffing with ndiff

**How to use:**
1. Run `ninjamenu`
2. Navigate to **Education > Network > Nmap > [technique]**
3. Select a script and follow the prompts for target IP/range

### Nmap-Unleashed

Enhanced nmap wrapper scripts:

**Scanning** — Automated scan workflows
- Auto scan with defaults, custom profiles, report-generating scans

**Reporting** — Export and format results
- HTML reports, XML export

**How to use:**
1. Run `ninjamenu`
2. Navigate to **Education > Network > Nmap-Unleashed > [technique]**
3. Select a script and follow the prompts

## Common Tasks

### Run Your First Scan

1. Install nmap: **NinjaMenu > Network > nmap**
2. Go to **Education > Network > Nmap > Scanning**
3. Select **Quick Scan** for a fast top-100 port scan
4. Enter a target IP when prompted

### Compare Two Scans Over Time

1. Go to **Education > Network > Nmap > Output**
2. Run **Save All Formats** against your target (saves a baseline)
3. Wait, then run it again
4. Run **Diff Scans** to see what changed

### Check SSL/TLS Security

1. Go to **Education > Network > Nmap > Vulnerability**
2. Select **SSL Audit**
3. Enter the target hostname or IP

## Troubleshooting

### Script says binary not found

**Symptom:** Script is blocked with a "binary not found" message.

**Solution:** Install the required tool first. For nmap scripts, go to **Network > nmap**. For nmap-unleashed scripts, go to **Network > nmap-tools-bundle**.

### Permission denied on scan

**Symptom:** Script fails with permission error.

**Solution:** Some scripts require root. Check the Root column in the script's README. The menu will prompt for sudo when needed.

## FAQ

**Q: Do these scripts modify my system?**
A: No. Education scripts only run tool commands (scans, reports). They do not install or uninstall software.

**Q: Can I use these on production networks?**
A: These are educational tools. Only scan networks you own or have explicit permission to test.

## See Also

- [Technical Manual](../technical_manuals/education.md)
- [Network Tools User Guide](./network.md)
