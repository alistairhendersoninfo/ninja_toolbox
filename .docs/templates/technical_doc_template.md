# {Category Name} - Technical Manual

## Architecture

{How this category's scripts are structured and why}

## Scripts Reference

### {script-name.sh}

**Purpose:** {What it does technically}

**Location:** `mainmenu/{category}/{script-name.sh}`

**YAML Header:**
```yaml
name: "{Display Name}"
description: "{Description}"
type: install|config
root: true|false
order: {number}
check_command: "{command}"
check_path: "{path}"
tags:
  - {tag}
```

**Functions:**
- `install()` - {What it does}
- `uninstall()` - {What it does}

**Dependencies:**
- {dependency 1}
- {dependency 2}

**Exit Codes:**
- `0` - Success
- `1` - Error

**Log Output:** `.docs/logs/{script-name}_YYYYMMDD_HHMMSS.log`

### {next-script.sh}

{Repeat for each script}

## Integration Points

### External Services
- {Service 1}: {How it's used}

### File Locations
- Config: `{path}`
- Data: `{path}`
- Logs: `{path}`

## Security Considerations

- {Security item 1}
- {Security item 2}

## Development

### Adding a New Script

1. Copy template: `cp .docs/templates/script_template.sh mainmenu/{category}/{name}.sh`
2. Edit YAML header
3. Implement `install()` function
4. Test with `bash mainmenu/{category}/{name}.sh install`

### Testing

```bash
# Test individual script
bash mainmenu/{category}/{script}.sh install

# Verify in menu
ninjamenu --submenu {category}
```

## Changelog

- **v1.0.0** - Initial implementation

## See Also

- [User Guide](../user_manuals/{folder}.md)
