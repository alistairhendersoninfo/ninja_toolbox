---
layout: page
title: About
nav_order: 2
description: "About the NinjaMenu project and its goals."
permalink: /about/
---

# About NinjaMenu

## The Story

NinjaMenu was born from the frustration of repeatedly setting up Linux workstations and VMs. Every time -- the same hunt for package names, the same forgotten configuration steps, the same wasted hours. What started as a personal shell script collection grew into a full menu system that anyone can use and contribute to.

## Project Goals

1. **Eliminate repetitive setup work** -- Automate what should be automated
2. **Stay organised** -- Folder-based menu structure that grows naturally
3. **Be cross-platform** -- Work on Linux and macOS with the same scripts
4. **Teach as you go** -- Education scripts show how tools work, not just install them
5. **Stay open** -- MIT licensed, community-driven, easy to contribute to

## The Name

Good tools should be like a ninja:
- **Fast** -- Get in, install, get out
- **Silent** -- No unnecessary output or bloat
- **Precise** -- Do exactly what you need, nothing more
- **Ready** -- Always there when you need them

## Technology Stack

| Component | Technology |
|-----------|-----------|
| Menu System | Python with gum (Charm.sh), whiptail, textual |
| Scripts | Bash with YAML headers for metadata |
| Platform Library | `.lib/platform.sh` -- cross-platform abstraction |
| Documentation | Jekyll on GitHub Pages |

## How It Works

The menu system is built around a simple idea: **folders become menus, scripts become menu items**.

```
mainmenu/
├── monitoring/     # becomes the "Monitoring" submenu
│   ├── htop.sh     # becomes the "htop" menu item
│   └── btop.sh     # becomes the "btop" menu item
└── network/        # becomes the "Network" submenu
    └── nmap.sh     # becomes the "nmap" menu item
```

Every script includes a YAML header with metadata -- name, description, whether it needs root, how to check if it's already installed. The menu reads these headers to build the interface dynamically. Drop a new script in a folder and it appears in the menu automatically.

## Supported Platforms

| Platform | Package Manager | Status |
|----------|----------------|--------|
| Kali Linux | apt | Fully supported |
| Debian | apt | Fully supported |
| Ubuntu | apt | Fully supported |
| macOS (Intel) | Homebrew | Fully supported |
| macOS (Apple Silicon) | Homebrew | Fully supported |

## License

NinjaMenu is released under the [MIT License](https://github.com/alistairhendersoninfo/ninja_toolbox/blob/main/LICENSE).
