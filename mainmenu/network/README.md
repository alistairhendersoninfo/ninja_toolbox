# Network Tools

Comprehensive suite of network analysis and security tools.

## Scripts

| Script | Description | Type |
|--------|-------------|------|
| Install All | Install all network tools at once | install |
| nmap-tools-bundle | Nmap, Zenmap GUI, and nmapUnleashed scanning suite | install |
| nmap | Network scanner | install |
| masscan | Fast port scanner | install |
| tcpdump | Packet capture | install |
| wireshark | GUI/CLI packet analyzer | install |
| netcat | TCP/UDP Swiss Army knife | install |
| mtr | Network diagnostic tool | install |
| nethogs | Per-process bandwidth | install |
| arp-scan | ARP scanner | install |
| netdiscover | Network discovery | install |
| net-tools | netstat, ifconfig, route | install |
| socat | Socket relay | install |
| vnstat | Traffic statistics | install |
| whois | WHOIS lookup | install |
| httpie | Modern HTTP client | install |
| sslscan | SSL/TLS scanner | install |

## Quick Start

```bash
ninjamenu
# Navigate to: Network -> pick individual tool or Install All
```

## Included Tools

### Network Info
- **net-tools** - netstat, ifconfig, route
- **iproute2** - ip, ss (modern replacements)
- **mtr** - Network diagnostic tool

### Scanning & Discovery
- **nmap-tools-bundle** - Nmap + Zenmap GUI + nmapUnleashed (bundle install)
- **nmap** - Network scanner
- **masscan** - Fast port scanner
- **arp-scan** - ARP scanner
- **netdiscover** - Network discovery

### DNS Tools
- **dig** - DNS lookup
- **nslookup** - DNS query
- **whois** - WHOIS lookup

### Packet Analysis
- **tcpdump** - Packet capture
- **wireshark** - GUI packet analyzer
- **tshark** - CLI Wireshark

### Traffic Monitoring
- **iftop** - Bandwidth monitor
- **nethogs** - Per-process bandwidth
- **vnstat** - Traffic statistics

### Connection Tools
- **netcat (nc)** - TCP/UDP Swiss Army knife
- **socat** - Socket relay
- **curl/wget** - HTTP clients

## Documentation

- [User Guide](../../.docs/user_manuals/network.md) - Usage instructions
- [Technical Manual](../../.docs/technical_manuals/network.md) - Developer docs

## Requirements

- Root access for installation
- Some tools require elevated privileges to run (tcpdump, nmap)

## Tags

`network` `security` `nmap` `wireshark` `tcpdump` `netstat`
