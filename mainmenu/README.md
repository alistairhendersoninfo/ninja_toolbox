# Main Menu

Root menu for the NinjaMenu toolbox. Each subfolder generates a top-level menu category.

## Categories

| Category | Description |
|----------|-------------|
| [education](education/) | Educational tool scripts — demonstrations and automation using installed tools |
| [git](git/) | Git workflow tools and configuration |
| [llm](llm/) | LLM tools — CLI assistants, IDE integrations, Claude Code |
| [monitoring](monitoring/) | System monitoring and observability tools |
| [network](network/) | Network analysis, scanning, and security tools |
| [postsetup-kali](postsetup-kali/) | Post-installation setup scripts for Kali Linux |
| [proxmox](proxmox/) | Proxmox virtualisation management tools |

## Quick Start

```bash
ninjamenu
# Select a category from the main menu
```

## How It Works

- **Folders** become menu categories (title-cased from folder name)
- **Scripts (.sh)** become menu items (name from YAML header)
- **Dot-prefixed** folders are hidden from the menu
- Sort order is controlled by the `order:` field in each script's YAML header
