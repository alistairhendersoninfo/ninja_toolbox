# Kali Menu Installer System

## Project Overview

A dynamic, folder-based menu system for Kali Linux that generates menus from directory structure. Uses modern TUI (Text User Interface) tools for a professional installation experience.

## Architecture

### Folder Structure
```
menu-installer/
├── .claude/              # Claude Code project files
│   ├── CLAUDE.md         # This file
│   ├── TODO.md           # Task tracking
│   ├── agents/           # Custom agent definitions
│   └── skills/           # Custom skill definitions
├── .configs/             # Configuration files (JSON, XML, YAML)
├── .docs/                # Documentation
│   ├── templates/        # Script templates
│   ├── user_manuals/     # End-user documentation
│   ├── technical_manuals/# Developer documentation
│   ├── logs/             # Installation logs
│   └── prompt.md         # Original requirements
├── .postinstalls/        # Scripts run after main installations
├── .preinstalls/         # Scripts run before main installations
├── mainmenu/             # Main menu structure
│   ├── llm/              # LLM Tools submenu
│   │   ├── cli/          # CLI tools submenu
│   │   └── ide/          # IDE tools submenu
│   └── postsetup-kali/   # Post-setup scripts submenu
├── install_menu.sh       # Menu system installer (hidden from menu)
└── menu.py               # Main menu application
```

### Menu Generation Rules

1. **Folders** = Menu/Submenu names (display name from folder name, titlecased)
2. **Scripts (.sh)** = Menu items (name from YAML header)
3. **Dot-prefixed** = Hidden from menu (`.configs`, `.docs`, etc.)
4. **YAML Headers** = Script metadata for menu display and execution

## Script YAML Header Format

All executable scripts must have a YAML header:

```bash
#!/bin/bash
# ---
# name: "Human Readable Name"
# description: "What this script does"
# version: "1.0.0"
# author: "Author Name"
# type: install
# root: true|false
# order: 10
# hidden: false
# installed: false
# check_command: "myapp --version"
# check_path: "/usr/bin/myapp"
# uninstall: "path/to/uninstall_script.sh"  # Optional
# dependencies:
#   - package1
#   - package2
# tags:
#   - category1
#   - category2
# ---
```

### Header Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Display name in menu |
| description | string | Yes | Brief description shown in menu |
| version | string | No | Script version |
| author | string | No | Script author |
| type | string | No | `install` (Install/Uninstall) or `config` (Run only) |
| root | boolean | Yes | Requires sudo/root privileges |
| order | integer | Yes | Sort order in menu (lower = higher) |
| hidden | boolean | No | If true, hide from menu |
| installed | boolean | No | Tracks installation state |
| check_command | string | No | Command to verify installation (e.g., `node --version`) |
| check_path | string | No | Path to check if exists (e.g., `/usr/bin/node`) |
| uninstall | string | No | Path to uninstall script |
| dependencies | array | No | Required packages |
| tags | array | No | Categorization tags |

### Script Types

- **`type: install`** (default) - Shows Install/Uninstall actions, tracks installation state
- **`type: config`** - Shows "Run" action only, for utilities/config scripts

## Menu System

### Technology Stack

- **Primary**: Python with `textual` library (modern, async TUI)
- **Fallback**: `gum` (Charm.sh) for beautiful prompts
- **Legacy Fallback**: `whiptail`/`dialog`

### Features

- Dynamic menu generation from folder structure
- YAML header parsing for script metadata
- Installation state tracking
- Log viewing capability
- Uninstall support
- Root privilege handling
- Progress indicators
- Color-coded status

## Documentation Requirements

### When Creating a New Menu Folder

Every menu folder MUST have:

1. **README.md** - Folder-level documentation (shown on GitHub)
   - Template: `.docs/templates/folder_readme_template.md`
   - Lists all scripts in the folder
   - Links to user and technical docs

2. **User Manual** - End-user documentation
   - Location: `.docs/user_manuals/{folder}.md`
   - Template: `.docs/templates/user_doc_template.md`
   - How to use each tool, common tasks, troubleshooting

3. **Technical Manual** - Developer documentation
   - Location: `.docs/technical_manuals/{folder}.md`
   - Template: `.docs/templates/technical_doc_template.md`
   - Architecture, script details, integration points

### Documentation Checklist

When adding a new script or folder:
- [ ] Script has complete YAML header
- [ ] Folder has README.md
- [ ] User manual exists in `.docs/user_manuals/`
- [ ] Technical manual exists in `.docs/technical_manuals/`
- [ ] README.md links to both manuals

### Templates Location

```
.docs/templates/
├── script_template.sh        # Install script template
├── config_template.sh        # Config/utility script template
├── folder_readme_template.md # Folder README template
├── user_doc_template.md      # User manual template
└── technical_doc_template.md # Technical manual template
```

## Development Guidelines

### Adding New Scripts

1. Create script in appropriate folder under `mainmenu/`
2. Copy from `.docs/templates/script_template.sh` or `config_template.sh`
3. Add YAML header with all required fields
4. Set `check_command` and/or `check_path` for installation detection
5. Use logging functions to write to `.docs/logs/`
6. Test with `bash script.sh install`
7. Update folder README.md with new script
8. Update user and technical manuals

### Creating Submenus

1. Create a new folder under the parent menu
2. Create README.md from template
3. Create user manual in `.docs/user_manuals/{folder}.md`
4. Create technical manual in `.docs/technical_manuals/{folder}.md`
5. Add scripts to the folder
6. Menu system auto-discovers on next run

### Logging

All scripts should log to `.docs/logs/<script_name>_<timestamp>.log`

```bash
LOG_FILE="$MENU_ROOT/.docs/logs/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
```

## Commands

```bash
# Install menu system dependencies
./install_menu.sh

# Launch menu
./menu.py

# Launch with specific submenu
./menu.py --submenu llm/cli

# List all available scripts
./menu.py --list

# Run specific script directly
./menu.py --run mainmenu/llm/cli/claude.sh
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| MENU_ROOT | Base directory of menu-installer |
| MENU_LOG_DIR | Log output directory |
| MENU_DRY_RUN | If set, scripts run in dry-run mode |

## Git Workflow Rules

- **NEVER push directly to main** — all changes must go through a Pull Request
- Use `/create-pr` to scaffold a new feature branch and open a draft PR
- Use `/review-tasks` to read code review comments and create todo tasks
- Use `/approve-pr` to verify review issues are resolved and merge (admin only)
- Use `/merge-pr` for standard merge workflow (non-admin or when review is already approved)
- Commit messages should be clear and describe the "why" not just the "what"
- One feature/fix per branch, one branch per PR

## Code Style

- Bash scripts: Use shellcheck compliance
- Python: Follow PEP 8, use type hints
- YAML: 2-space indentation
- Comments: Explain why, not what
