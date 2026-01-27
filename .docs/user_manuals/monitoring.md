# System Monitoring - User Guide

## Overview

System monitoring tools for tracking performance, processes, I/O, and resource usage.

## Available Tools

### System Monitoring Tools

Installs a comprehensive suite of monitoring applications:

#### htop
Interactive process viewer with color display.
```bash
htop
```
- Use arrow keys to navigate
- F9 to kill process
- F10 to quit

#### iotop
Monitor disk I/O by process.
```bash
sudo iotop
```

#### btop
Modern, beautiful resource monitor.
```bash
btop
```

#### glances
Cross-platform monitoring with web interface.
```bash
glances           # Terminal mode
glances -w        # Web server mode
```

#### ncdu
Disk usage analyzer.
```bash
ncdu /            # Analyze root
ncdu ~            # Analyze home
```

## Common Tasks

### Check System Load
```bash
htop              # Interactive
uptime            # Quick load average
```

### Find Disk Space Usage
```bash
ncdu /home        # Interactive
duf               # Quick summary
```

### Monitor I/O
```bash
sudo iotop        # Per-process I/O
iostat 1          # Disk I/O stats
```

### Check Temperatures
```bash
sensors           # Hardware temps
```

## See Also

- [Technical Manual](../technical_manuals/monitoring.md)
