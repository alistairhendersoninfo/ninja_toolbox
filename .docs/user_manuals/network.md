# Network Tools - User Guide

## Overview

Comprehensive network analysis, scanning, and security tools.

## Available Tools

### Network Tools Suite

Installs all essential networking utilities.

## Common Tasks

### View Network Interfaces
```bash
ip a              # Modern
ifconfig          # Legacy
```

### View Active Connections
```bash
ss -tuln          # Modern (listening)
netstat -tuln     # Legacy (listening)
ss -tup           # Connected with process
```

### Scan Network
```bash
nmap 192.168.1.0/24           # Quick scan
nmap -sV 192.168.1.1          # Service detection
sudo nmap -O 192.168.1.1      # OS detection
```

### DNS Lookup
```bash
dig example.com
nslookup example.com
host example.com
```

### Trace Route
```bash
mtr google.com    # Interactive
traceroute google.com
```

### Capture Packets
```bash
sudo tcpdump -i eth0
sudo tcpdump -i eth0 port 80
sudo tcpdump -i eth0 -w capture.pcap
```

### Test Port
```bash
nc -zv host 22           # Test SSH port
nc -l 8080               # Listen on port
```

### Monitor Bandwidth
```bash
sudo iftop -i eth0       # Per-connection
sudo nethogs eth0        # Per-process
```

### Check WHOIS
```bash
whois example.com
whois 8.8.8.8
```

## Troubleshooting

### Permission Denied
Most network tools require root:
```bash
sudo nmap ...
sudo tcpdump ...
```

### Interface Not Found
List available interfaces:
```bash
ip link show
```

## See Also

- [Technical Manual](../technical_manuals/network.md)
