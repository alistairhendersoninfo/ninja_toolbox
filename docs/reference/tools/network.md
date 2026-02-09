---
layout: default
title: Network
parent: Tool Reference
grand_parent: Documentation
nav_order: 2
---

<img src="{{ '/assets/images/it_nerd_14213d.png' | relative_url }}" alt="IT Nerd" style="float: right; width: 120px; margin-left: 1rem;" />

# Network Tools

Comprehensive network analysis, scanning, and security tools.

**Location:** [`mainmenu/network/`](https://github.com/alistairhendersoninfo/ninja_toolbox/tree/main/mainmenu/network)

## Available Tools

### Scanning

| Tool | Description | Check Command |
|------|-------------|---------------|
| nmap | Network mapper and port scanner | `nmap --version` |
| masscan | Fast mass IP port scanner | `masscan --version` |
| arp-scan | ARP scanning and fingerprinting | `arp-scan --version` |
| netdiscover | Active/passive ARP reconnaissance | `netdiscover -h` |

### Packet Analysis

| Tool | Description | Check Command |
|------|-------------|---------------|
| tcpdump | Command-line packet analyser | `tcpdump --version` |
| wireshark | GUI network protocol analyser | `wireshark --version` |
| tshark | Terminal-based Wireshark | `tshark --version` |
| ngrep | Network grep | `ngrep -h` |

### Traffic Monitoring

| Tool | Description | Check Command |
|------|-------------|---------------|
| iftop | Bandwidth usage per connection | `iftop -h` |
| nethogs | Bandwidth usage per process | `nethogs -V` |
| vnstat | Network traffic accounting | `vnstat --version` |
| bmon | Bandwidth monitor and rate estimator | `bmon --version` |

### Connection Tools

| Tool | Description | Check Command |
|------|-------------|---------------|
| netcat | TCP/UDP networking utility | `nc -h` |
| socat | Multipurpose relay tool | `socat -V` |
| curl | URL transfer tool | `curl --version` |
| httpie | User-friendly HTTP client | `http --version` |

### Security & SSL

| Tool | Description | Check Command |
|------|-------------|---------------|
| sslscan | SSL/TLS scanner | `sslscan --version` |
| mtr | Combined traceroute and ping | `mtr --version` |

There is also an **Install All** script that installs the entire network suite.

## Common Tasks

### Scan a Network

```bash
nmap 192.168.1.0/24           # Quick host discovery
nmap -sV 192.168.1.1          # Service version detection
sudo nmap -O 192.168.1.1      # OS detection
```

### Capture Packets

```bash
sudo tcpdump -i eth0                  # All traffic on interface
sudo tcpdump -i eth0 port 80          # HTTP traffic only
sudo tcpdump -i eth0 -w capture.pcap  # Save to file
```

### Test a Port

```bash
nc -zv host 22           # Test SSH port
nc -l 8080               # Listen on port
```

### Monitor Bandwidth

```bash
sudo iftop -i eth0       # Per-connection bandwidth
sudo nethogs eth0        # Per-process bandwidth
```

### DNS and Routing

```bash
dig example.com          # DNS lookup
mtr google.com           # Interactive traceroute
```

## Technical Details

- Many network tools require root to access raw sockets
- Scripts marked with `root: true` handle privilege escalation automatically
- On macOS, some package names differ (e.g., `wireshark` installs as a Homebrew cask)
- The nmap tools bundle installs the full nmap ecosystem (nmap, ncat, nping, ndiff, zenmap)

{: .warning }
Network scanning tools should only be used on systems you own or have explicit authorisation to test.
