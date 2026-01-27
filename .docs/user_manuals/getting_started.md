# Kali Menu Installer - User Guide

## Getting Started

### Installation

1. **Install the menu system**:
   ```bash
   cd ~/menu-installer
   sudo ./install_menu.sh
   ```

2. **Launch the menu**:
   ```bash
   ninjamenu
   ```

   Or from the install directory:
   ```bash
   ./menu
   ```

### Menu Navigation

#### Using the Modern Menu (Gum/Textual)

- **Arrow keys**: Navigate up/down through options
- **Enter**: Select an item
- **Escape/q**: Go back or quit
- **l**: View installation log for selected item

#### Menu Icons

| Icon | Meaning |
|------|---------|
| 📁 | Submenu (folder) |
| ⬜ | Not installed |
| ✅ | Installed |
| 🔐 | Requires root/sudo |

### Installing Software

1. Navigate to the desired category
2. Select the software to install
3. Choose "Install" from the action menu
4. Wait for installation to complete
5. Press Enter to return to menu

### Uninstalling Software

1. Navigate to an installed item (shows ✅)
2. Select the item
3. Choose "Uninstall" from the action menu
4. Confirm the uninstallation

### Viewing Logs

Logs are stored in `.docs/logs/` and can be viewed:

1. From the menu: Select an item and choose "View Log"
2. From terminal:
   ```bash
   ls ~/.menu-installer/.docs/logs/
   less ~/.menu-installer/.docs/logs/<script>_<date>.log
   ```

### Command Line Options

```bash
# List all available scripts
ninjamenu --list

# Run a specific script directly
ninjamenu --run mainmenu/llm/cli/claude-cli.sh

# Start at a specific submenu
ninjamenu --submenu llm/cli

# Force a specific UI
ninjamenu --tui gum
ninjamenu --tui whiptail
ninjamenu --tui textual
```

## Menu Structure

```
mainmenu/
├── llm/                    # LLM & AI Tools
│   ├── cli/                # Command-line interfaces
│   │   ├── claude-cli      # Anthropic Claude CLI
│   │   ├── gemini-cli      # Google Gemini CLI
│   │   └── codex-cli       # OpenAI Codex CLI
│   └── ide/                # Integrated Development Environments
│       ├── cursor          # Cursor AI Editor
│       └── antigravity     # Google Antigravity IDE
└── postsetup-kali/         # Kali Post-Setup Tools
    ├── nodejs              # Node.js 20 LTS
    ├── fix-zsh             # Fix ZSH configuration
    ├── proxmox-tools       # Proxmox guest agent
    └── catppuccin-themes   # Catppuccin color themes
```

## Troubleshooting

### Menu doesn't start

1. Ensure you've run `sudo ./install_menu.sh`
2. Try forcing whiptail: `./menu --tui whiptail`

### Script fails with permission error

- Scripts marked with 🔐 require sudo
- Run with: `sudo ./menu`

### Installation log shows errors

1. View the log: Select item > "View Log"
2. Check for missing dependencies
3. Ensure you have internet connectivity

## Getting Help

- Press `?` in the menu for help
- Check logs in `.docs/logs/`
- Read technical documentation in `.docs/technical_manuals/`
