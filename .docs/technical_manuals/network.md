# Network Tools - Technical Manual

## Architecture

Single script installs comprehensive networking toolkit via apt.

## Scripts Reference

### network-tools.sh

**Purpose:** Install complete network analysis toolkit

**Location:** `mainmenu/network/network-tools.sh`

**YAML Header:**
```yaml
name: "Network Tools Suite"
type: install
root: true
order: 10
check_command: "nmap --version"
check_path: "/usr/bin/nmap:/usr/bin/netstat"
```

**Packages Installed:**

Core Networking:
- net-tools (netstat, ifconfig)
- iproute2 (ip, ss)
- mtr, traceroute

Scanning:
- nmap, masscan
- arp-scan, netdiscover

Packet Analysis:
- tcpdump, wireshark, tshark, ngrep

Traffic Monitoring:
- iftop, nethogs, bmon, vnstat

Connection Tools:
- netcat, socat, telnet
- curl, wget, httpie

Security:
- openssl, sslscan, sslyze
- aircrack-ng, macchanger

**Uninstall Behavior:**
- Removes non-essential tools only
- Preserves core utilities (nmap, tcpdump, net-tools)

## Security Considerations

- Many tools require root to run
- Some tools (nmap, aircrack-ng) can be used for unauthorized access
- Use responsibly and only on authorized systems

## Development

### Adding New Network Tools

1. Add package to PACKAGES array
2. Categorize in appropriate section
3. Test on clean system
4. Document in user manual

## See Also

- [User Guide](../user_manuals/network.md)
