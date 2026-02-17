---
name: ninja-rebuild
description: "Rebuild the SQLite menu cache from YAML metadata files"
argument-hint: "[--check-installed]"
disable-model-invocation: true
allowed-tools: Bash, Read
---

# Ninja Rebuild

Force-rebuild the SQLite menu cache (`.cache/menu.db`) from YAML metadata files.

**Usage:** `/ninja-rebuild` or `/ninja-rebuild --check-installed`

## Execution

Run the rebuild script:

```bash
.claude/scripts/ninja-rebuild.sh $ARGUMENTS
```

The script:
1. Activates the Python venv
2. Runs `menu.py --rebuild` to rebuild the cache from all YAML metadata
3. Optionally runs `check_command` for every script if `--check-installed` is passed
4. Reports the number of scripts and submenus cached

## When to use

- After adding, removing, or modifying `.meta.yaml` / `meta.yaml` files
- After bulk changes to the `mainmenu/` directory structure
- If the menu displays stale data
- With `--check-installed` to refresh installation status for all scripts

## Print summary

After the script completes, confirm:
```
Cache rebuilt. <N> scripts, <M> submenus.
```
