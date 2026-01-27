# System Monitoring - Technical Manual

## Architecture

Single script installs multiple monitoring packages via apt.

## Scripts Reference

### system-monitors.sh

**Purpose:** Install comprehensive monitoring tools

**Location:** `mainmenu/monitoring/system-monitors.sh`

**YAML Header:**
```yaml
name: "System Monitoring Tools"
type: install
root: true
order: 10
check_command: "htop --version"
check_path: "/usr/bin/htop:/usr/bin/iotop"
```

**Packages Installed:**
- Process: htop, atop, btop, glances
- I/O: iotop, iftop, dstat
- Info: neofetch, inxi, lshw, hwinfo
- Disk: ncdu, duf
- Memory: smem
- Performance: sysstat, nmon

**Requirements:**
- Some tools need kernel config (iotop needs CONFIG_TASK_IO_ACCOUNTING)
- btop may not be available on older systems

## Development

### Adding New Monitoring Tools

1. Add package to PACKAGES array
2. Test installation on clean system
3. Update README and documentation

## See Also

- [User Guide](../user_manuals/monitoring.md)
