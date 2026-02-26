# Maintenance UTM

VM guest maintenance and housekeeping utilities for UTM-hosted virtual machines.

## Scripts

| Script | Description | Type |
|--------|-------------|------|
| Reset Time Sync | Fix clock drift in UTM VM: prompt for correct time, install chrony, configure aggressive VM sync | config |

## Quick Start

```bash
ninjamenu
# Navigate to: Maintenance UTM -> Reset Time Sync
```

## Documentation

- [User Guide](../../.docs/user_manuals/maintenance-utm.md) - How to use these tools
- [Technical Manual](../../.docs/technical_manuals/maintenance-utm.md) - Developer documentation

## Requirements

- Kali Linux, Debian, or Ubuntu (as a UTM VM guest)
- Root / sudo access

## Tags

`maintenance` `utm` `time` `chrony`
