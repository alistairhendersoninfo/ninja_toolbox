# NinjaMenu

A dynamic TUI menu system for Kali Linux that provides easy installation and management of tools and utilities.

## Features

- **Dynamic Menu Generation** - Menus built automatically from folder structure
- **Multiple TUI Backends** - Choose between gum (modern), whiptail (classic), or textual (Python)
- **YAML Script Headers** - Scripts define their own metadata (name, description, root requirements, etc.)
- **Install Status Tracking** - See at a glance which tools are installed
- **Keyboard Navigation** - Number keys for quick selection, b=back, x=exit

## Quick Start

```bash
# Install the menu system
sudo ./install_menu.sh

# Launch the menu
ninjamenu
```

## Menu Structure

```
mainmenu/
├── git/           # Git configuration and tools
├── llm/           # LLM tools (Claude, CLI tools, IDE extensions)
│   └── claude/    # Claude Code CLI and skills
├── monitoring/    # System monitoring tools (htop, btop, glances, etc.)
├── network/       # Network tools (nmap, wireshark, tcpdump, etc.)
├── postsetup-kali/# Kali post-installation setup
└── proxmox/       # Proxmox helper scripts
```

## Configuration

Settings are stored in `.configs/menusystem/settings.conf`:

```conf
# Backend options: gum, whiptail, textual
backend=gum

# Gum styling
gum.border=rounded
gum.border_foreground=99
gum.height=15
```

## Creating Scripts

Scripts use YAML headers for metadata:

```bash
#!/bin/bash
# ---
# name: "My Tool"
# description: "What this tool does"
# version: "1.0.0"
# root: true
# type: install
# check_command: "mytool --version"
# tags: [tools, utilities]
# ---

# Your script here...
```

### Header Fields

| Field | Description |
|-------|-------------|
| `name` | Display name in menu |
| `description` | Brief description |
| `version` | Script version |
| `root` | Requires sudo (true/false) |
| `type` | `install` (install/uninstall) or `config` (run only) |
| `check_command` | Command to verify if installed |
| `check_path` | Path to check if exists |
| `order` | Sort order (lower = higher) |
| `hidden` | Hide from menu (true/false) |
| `tags` | Categorization tags |

## Command Line Options

```bash
ninjamenu                    # Launch menu
ninjamenu --list             # List all scripts
ninjamenu --submenu llm      # Start at submenu
ninjamenu --tui whiptail     # Force specific backend
ninjamenu --run <script>     # Run script directly
```

## Claude Skills

The project includes installable Claude Code skills in `mainmenu/llm/claude/.skills/`:

- **git-commit** - Structured git commit workflow

Install skills using the "Install Claude Skills" option in the LLM > Claude menu.

## Requirements

- Python 3.8+
- gum (Charm.sh) - for modern TUI
- whiptail/dialog - for classic TUI
- PyYAML, textual, rich (installed via install_menu.sh)

## License

MIT
