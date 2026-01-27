# Kali Menu Installer - Technical Documentation

## Architecture Overview

The menu system is designed around a folder-based configuration approach where the directory structure defines the menu hierarchy.

### Core Components

```
menu-installer/
├── menu.py              # Main application (Python/Textual)
├── menu                  # Launcher script
├── install_menu.sh      # Bootstrap installer
├── .venv/               # Python virtual environment
├── mainmenu/            # Menu definition (folder structure)
├── .configs/            # Configuration files
├── .docs/               # Documentation and logs
├── .preinstalls/        # Pre-installation hooks
├── .postinstalls/       # Post-installation hooks
└── .claude/             # Claude Code project files
```

### Menu Generation Algorithm

```python
def scan_menu_directory(directory):
    items = []
    for entry in directory.iterdir():
        if entry.name.startswith('.'):  # Skip hidden
            continue
        if entry.is_dir():
            items.append(MenuItem(submenu=True))
        elif entry.suffix == '.sh':
            info = parse_yaml_header(entry)
            if info and not info.hidden:
                items.append(MenuItem(script=info))
    return sorted(items, key=lambda x: (not x.is_submenu, x.order, x.name))
```

### YAML Header Parser

The parser extracts metadata from shell scripts using regex:

```python
pattern = r'^#\s*---\s*\n((?:#.*\n)*?)#\s*---'
```

This matches:
```bash
# ---
# name: "Example"
# description: "An example script"
# root: true
# order: 10
# ---
```

### TUI Backend Selection

Priority order:
1. **Textual** - Modern async TUI (if Python packages available)
2. **Gum** - Beautiful prompts (if installed)
3. **Whiptail** - Traditional TUI (fallback)

### Logging System

All scripts should follow this pattern:

```bash
LOG_DIR="$MENU_ROOT/.docs/logs"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
```

This captures all stdout/stderr to timestamped log files.

### Installation State Tracking

Scripts update their own YAML header:

```bash
mark_installed() {
    local status="${1:-true}"
    sed -i "s/^# installed: .*/# installed: $status/" "${BASH_SOURCE[0]}"
}
```

### Root Privilege Handling

When a script has `root: true`:
1. Menu prepends `sudo` to the command
2. Script should still verify with `check_root()`
3. User is prompted for password if needed

### Hook System

#### Pre-install Hooks (`.preinstalls/`)

Scripts here run before any installation:
- Dependency checking
- System preparation
- User confirmation

#### Post-install Hooks (`.postinstalls/`)

Scripts here run after installations:
- PATH updates
- Configuration adjustments
- Cleanup tasks

### Configuration Files (`.configs/`)

Store JSON, XML, YAML config files here:
- API keys templates
- Default configurations
- System settings

### Error Handling

Scripts should:
1. Use `set -euo pipefail`
2. Log all actions
3. Provide meaningful error messages
4. Clean up temporary files on exit

### Adding New Scripts

1. Create script in appropriate folder
2. Add YAML header (copy from template)
3. Implement `install()` and `uninstall()` functions
4. Test with `./menu --run path/to/script.sh`
5. Verify logging works

### Security Considerations

- Scripts run with user's permissions (unless root required)
- No credentials stored in scripts
- Logs may contain sensitive output (consider in production)
- Downloaded packages verified when possible

## API Reference

### ScriptInfo Class

```python
@dataclass
class ScriptInfo:
    path: Path
    name: str
    description: str
    version: str
    author: str
    root: bool
    order: int
    hidden: bool
    installed: bool
    uninstall: str
    dependencies: List[str]
    tags: List[str]
```

### MenuItem Class

```python
@dataclass
class MenuItem:
    name: str
    path: Path
    is_submenu: bool
    script_info: Optional[ScriptInfo]
    order: int
```

### Key Functions

| Function | Description |
|----------|-------------|
| `parse_yaml_header(path)` | Extract YAML metadata from script |
| `scan_menu_directory(dir)` | Get all menu items from folder |
| `run_script(info, action)` | Execute a script with logging |
| `view_log(name)` | Display most recent log file |

## Development Workflow

1. Fork/clone the repository
2. Create feature branch
3. Add/modify scripts following template
4. Test with `./menu --list` and `./menu --run`
5. Update documentation if needed
6. Submit changes

## Future Enhancements

- [ ] Remote script repository
- [ ] Version checking and updates
- [ ] Batch installation mode
- [ ] Web-based interface
- [ ] Plugin system for custom TUI backends
