---
layout: default
title: Monitoring
parent: Tool Reference
grand_parent: Documentation
nav_order: 1
---

<img src="{{ '/assets/images/it_nerd_14213d.png' | relative_url }}" alt="IT Nerd" style="float: right; width: 120px; margin-left: 1rem;" />

# Monitoring Tools

System monitoring tools for tracking performance, processes, I/O, and resource usage.

**Location:** [`mainmenu/monitoring/`](https://github.com/alistairhendersoninfo/ninja_toolbox/tree/main/mainmenu/monitoring)

## Available Tools

| Tool | Description | Check Command |
|------|-------------|---------------|
| htop | Interactive process viewer with colour display | `htop --version` |
| btop | Modern, feature-rich resource monitor | `btop --version` |
| atop | Advanced system and process monitor | `atop -V` |
| glances | Cross-platform monitoring with web interface | `glances --version` |
| iotop | Monitor disk I/O by process | `iotop --version` |
| iftop | Display bandwidth usage on an interface | `iftop -h` |
| ncdu | Interactive disk usage analyser | `ncdu -v` |
| duf | Modern disk usage utility | `duf --version` |
| neofetch | System information display | `neofetch --version` |
| inxi | Full-featured system information tool | `inxi -V` |
| sysstat | System performance tools (sar, iostat, mpstat) | `sar -V` |
| nmon | Performance monitor for Linux | `nmon -h` |

There is also an **Install All** script that installs the entire monitoring suite at once.

## Common Tasks

### Check System Load

```bash
htop              # Interactive process view
btop              # Modern alternative with graphs
uptime            # Quick load average
```

### Find Disk Space Usage

```bash
ncdu /home        # Interactive disk analyser
duf               # Quick summary of all mounts
```

### Monitor I/O

```bash
sudo iotop        # Per-process I/O
iostat 1          # Disk I/O stats (from sysstat)
```

### Monitor Network per Interface

```bash
sudo iftop -i eth0    # Live bandwidth by connection
```

### System Information

```bash
neofetch          # Pretty system summary
inxi -Fxz        # Detailed hardware and software info
```

## Technical Details

- Most tools install via a single `pkg_install` call using `.lib/platform.sh`
- Tools requiring kernel features (e.g., iotop needs `CONFIG_TASK_IO_ACCOUNTING`) may not work on all systems
- btop may not be available on older distributions
- All scripts support install and uninstall actions
