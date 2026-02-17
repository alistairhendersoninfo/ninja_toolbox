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

1. **Folders with `meta.yaml`** = Tier 1 modular scripts (OS-specific, resolved per platform)
2. **Scripts (.sh) with sibling `.meta.yaml`** = Tier 2 scripts (OS-agnostic, most common)
3. **Scripts (.sh) with inline `# ---` header** = Tier 3 legacy (deprecated, still parsed)
4. **Folders without `meta.yaml`** = Submenus (display name from folder name, titlecased)
5. **Dot-prefixed** = Hidden from menu (`.configs`, `.docs`, etc.)
6. **Underscore-prefixed** (`_common.sh`) = Hidden from menu

## Script Metadata System

Scripts use **externalised YAML metadata** — not inline headers. There are three tiers:

| Tier | Structure | When to Use |
|------|-----------|-------------|
| **Tier 1** — Modular folder | `<tool>/meta.yaml` + `_common.sh` + `macos.sh`, `linux.sh` | Different code per OS (10 scripts) |
| **Tier 2** — Sibling `.meta.yaml` | `<tool>.sh` + `<tool>.meta.yaml` | Uses `pkg_install`/`pkg_remove` from platform.sh (71 scripts) |
| **Tier 3** — Inline YAML header | `# --- ... # ---` inside `.sh` | **Deprecated.** Do not use for new scripts |

### Tier 2 Example (most common)

```yaml
# htop.meta.yaml
name: "htop"
description: "Interactive process viewer with color display"
type: install
root: true
order: 10
installed: false
check_command: "htop --version"
tags:
  - monitoring
  - process
supported_os:
  - macos
  - kali
  - debian
  - ubuntu
```

### Required Metadata Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Display name in menu |
| description | string | Yes | Brief description shown in menu |
| type | string | Yes | `install`, `config`, or `tool` |
| root | boolean | Yes | Requires sudo/root privileges |
| order | integer | Yes | Sort order in menu (lower = higher) |
| supported_os | array | Yes | Which OSes this script supports (`macos`, `kali`, `debian`, `ubuntu`) |

For the full field reference and Tier 1 folder structure, see:
- **Contributing guide:** `mainmenu/CONTRIBUTING.md`
- **Full technical spec:** `.docs/technical_manuals/os-modular-architecture.md`

### Script Types

- **`type: install`** (default) - Shows Install/Uninstall actions, tracks installation state
- **`type: config`** - Shows "Run" action only, for utilities/config scripts
- **`type: tool`** - Educational scripts that use an installed binary (requires `binary` field)

## SQLite Menu Cache

The menu uses an SQLite cache (`.cache/menu.db`) to avoid scanning the filesystem on every render. YAML metadata files remain the single source of truth.

### Architecture

```
YAML (source of truth)          SQLite (.cache/menu.db)          Menu UI
───────────────────────         ───────────────────────          ────────
mainmenu/**/*.meta.yaml   ──►   rebuild_cache()            ──►   get_menu_items()
mainmenu/**/meta.yaml     ──►   (Python, on demand)        ──►   (SQL query, <15ms)
```

### Key Files

| File | Purpose |
|------|---------|
| `.app/cache.py` | Cache builder + query module (standalone, no TUI deps) |
| `.cache/menu.db` | SQLite database (gitignored, disposable) |
| `.claude/scripts/ninja-rebuild.sh` | Manual cache rebuild script |

### How It Works

1. **Startup**: `menu.py` checks if `.cache/menu.db` exists and is current
2. **Auto-rebuild**: If any `.meta.yaml` / `meta.yaml` mtime is newer than cached, rebuilds
3. **Menu render**: Queries SQLite instead of walking filesystem (~15ms vs 2-10s)
4. **Aliases**: Resolved via SQL JOIN on `alias_entries` table (no separate scan)
5. **Installed status**: Cached; updated lazily on script focus/select or after install/uninstall
6. **Manual rebuild**: `/ninja-rebuild` or `menu.py --rebuild`

### When to Rebuild

- After adding/removing/modifying `.meta.yaml` or `meta.yaml` files (auto-detected)
- After structural changes to `mainmenu/` directories
- With `--check-installed` flag to refresh all installation status checks

## Menu System

### Technology Stack

- **Primary**: Python with `textual` library (modern, async TUI)
- **Fallback**: `gum` (Charm.sh) for beautiful prompts
- **Legacy Fallback**: `whiptail`/`dialog`

### Features

- Dynamic menu generation from folder structure
- Three-tier metadata parsing (folder `meta.yaml`, sibling `.meta.yaml`, legacy inline)
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
- [ ] Metadata file exists (`meta.yaml` for Tier 1 or `.meta.yaml` for Tier 2)
- [ ] `supported_os` field lists all tested OSes
- [ ] Folder has README.md
- [ ] User manual exists in `.docs/user_manuals/`
- [ ] Technical manual exists in `.docs/technical_manuals/`
- [ ] README.md links to both manuals

### Templates Location

```
.docs/templates/
├── script_template.sh            # Tier 2 install script template
├── script_template.meta.yaml     # Tier 2 install metadata template
├── config_template.sh            # Tier 2 config/utility script template
├── config_template.meta.yaml     # Tier 2 config metadata template
├── tool_template.sh              # Tier 2 tool/education script template
├── tool_template.meta.yaml       # Tier 2 tool metadata template
├── tier1_template/               # Tier 1 modular folder template
│   ├── meta.yaml                 # Tier 1 metadata template
│   ├── _common.sh                # Shared functions template
│   ├── macos.sh                  # macOS script template
│   └── linux.sh                  # Linux script template
├── folder_readme_template.md     # Folder README template
├── user_doc_template.md          # User manual template
└── technical_doc_template.md     # Technical manual template
```

## Development Guidelines

### Adding New Scripts

1. Decide the tier: Tier 2 (OS-agnostic, most common) or Tier 1 (OS-specific)
2. **Scripts must go inside a category subfolder** — never place a script directly under a top-level menu folder. Top-level folders (e.g. `mainmenu/llm/`) should only contain category subfolders (`cli/`, `ide/`, `ai-tools/`, etc.), not loose scripts. If no suitable category exists, create one first (see "Creating Submenus" below).
3. Create script in the appropriate category folder under `mainmenu/`
4. Copy from `.docs/templates/` (use `script_template.sh` + `script_template.meta.yaml` for Tier 2, or `tier1_template/` for Tier 1)
5. Create the companion `.meta.yaml` (Tier 2) or `meta.yaml` (Tier 1) with all required fields including `supported_os`
6. Set `check_command` and/or `check_path` for installation detection
7. Use logging functions to write to `.docs/logs/`
8. Test with `bash script.sh install`
9. Update folder README.md with new script
10. Update user and technical manuals

### Creating Submenus

1. Create a new folder under the parent menu (this becomes a `📁` category in the menu)
2. **Every top-level menu section must use category subfolders** — scripts are never placed alongside subfolder siblings. A folder either contains only subfolders (category) or only scripts (leaf), never both.
3. Create README.md from template
4. Create user manual in `.docs/user_manuals/{folder}.md`
5. Create technical manual in `.docs/technical_manuals/{folder}.md`
6. Add scripts to the folder
7. Menu system auto-discovers on next run

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
- Use `/ship-it` to run the full end-to-end workflow: branch, commit, push, PR, merge
- Use `/create-pr` to scaffold a new feature branch and open a draft PR
- Use `/review-tasks` to read code review comments and create todo tasks
- Use `/approve-pr` to verify review issues are resolved and merge (admin only)
- Use `/merge-pr` for standard merge workflow (non-admin or when review is already approved)
- Use `/trigger-guardian` to test the Wiki Guardian spam detection workflow
- Commit messages should be clear and describe the "why" not just the "what"
- One feature/fix per branch, one branch per PR

### Available Skills

| Skill | Command | Description |
|-------|---------|-------------|
| Ship It | `/ship-it [branch] [message]` | Full workflow: branch → commit → push → PR → merge |
| Create PR | `/create-pr [feature-name]` | Scaffold a new feature branch with draft PR |
| Merge PR | `/merge-pr [pr-number]` | Check status and merge an existing PR |
| Approve PR | `/approve-pr [pr-number]` | Admin self-review gate before merge |
| Review Tasks | `/review-tasks [pr-number]` | Read PR review comments and create todo tasks |
| Trigger Guardian | `/trigger-guardian [spam]` | Test Wiki Guardian with a clean or spam wiki edit |
| PR Status | `/pr-status [number \| issue number]` | Show open PRs and issues, or detail view of a specific PR/issue |
| Ninja Rebuild | `/ninja-rebuild [--check-installed]` | Rebuild SQLite menu cache from YAML metadata |

## Site Characters

The site uses four illustrated characters across docs, pages, and wiki. See [`.claude/characters.md`](.claude/characters.md) for full bios, personality definitions, page assignments, and image variant guide.

| Character | Role | Pages |
|-----------|------|-------|
| **Little Tracey Ninja** | Site worker, day-to-day guides | About, Contribute, Getting Started, Wiki Home, Wiki Tips |
| **Big Tracey Ninja** | Site worker, day-to-day guides | Homepage, Contact, Contribute, Docs Hub, Tools Index, Wiki FAQ, Wiki Troubleshooting |
| **IT Nerd** | Old-school infrastructure guru | Architecture, Education, Monitoring, Network, LLM, Git, Postsetup-Kali, Proxmox, README |
| **IT Super Nerd** | The brains, deep technical content | Architecture, LLM, Education scripts, Wiki technical pages |

Image variants exist for each background colour:
- `_14213d` (Prussian Blue) — docs site pages
- `_000000` (Black) — wiki pages
- `_ffffff` (White) — GitHub README

## Brand Colour Palette

| Name | Hex | Role |
|------|-----|------|
| Black | `#000000` | Accents, deep backgrounds, wiki bg |
| Prussian Blue | `#14213d` | Site background |
| Orange | `#fca311` | Header, links, buttons, accents |
| Alabaster Grey | `#e5e5e5` | Footer |
| White | `#ffffff` | All text |

## GitHub Pages & Wiki

- **Pages site:** `docs/` directory, Jekyll with `just-the-docs` remote theme, custom `ninjamenu` colour scheme
- **Wiki:** `.wiki/` directory (synced to `*.wiki.git` repo separately)
- **Wiki Guardian:** `.github/scripts/wiki-guardian.sh` — automated spam detection on gollum events
- **Favicon:** `docs/assets/images/favicon.ico` wired via `docs/_includes/head_custom.html`
- **Image assets:** `docs/assets/images/` — 60+ variants (5 subjects x 6 backgrounds x 2 formats)

## Code Style

- Bash scripts: Use shellcheck compliance
- Python: Follow PEP 8, use type hints
- YAML: 2-space indentation
- Comments: Explain why, not what
