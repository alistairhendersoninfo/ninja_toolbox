# Contributing to NinjaMenu

Thanks for your interest in contributing. This guide explains how to add scripts, report issues, and submit changes.

## Adding a New Install Script

The quickest way to contribute is adding a new tool to the menu.

### 1. Pick the right folder

Drop your script into the matching category under `mainmenu/`:

| Folder | Purpose |
|--------|---------|
| `monitoring/` | System monitoring tools (htop, btop, etc.) |
| `network/` | Network scanning and analysis tools |
| `llm/` | AI/LLM tools and IDE extensions |
| `git/` | Git setup and configuration |
| `postsetup-kali/` | Kali-specific post-install tweaks |
| `proxmox/` | Proxmox VM management |

Need a new category? Create a folder under `mainmenu/` with a `README.md` describing it.

### 2. Use the YAML header

Every script **must** include a YAML header so the menu system can discover it:

```bash
#!/bin/bash
# ---
# name: "tool-name"
# description: "One-line description of what it does"
# type: install
# root: true
# order: 20
# check_command: "tool-name --version"
# tags: "category, keyword"
# ---
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Display name in the menu |
| `description` | Yes | Short description shown in detail view |
| `type` | Yes | `install` (adds software) or `config` (run-only) |
| `root` | Yes | `true` if the script needs sudo |
| `order` | No | Sort position (lower = higher in menu) |
| `check_command` | Yes* | Command to verify installation |
| `check_path` | Yes* | Alternative: check if a file path exists |
| `tags` | No | Comma-separated keywords for search |

*Provide either `check_command` or `check_path`.

### 3. Source the platform library

Every script **must** source the shared platform library for cross-platform support:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"
```

This gives you: `pkg_install`, `pkg_remove`, `require_root`, `mark_installed`, `nt_sed_i`, and all logging functions.

### 4. Support install and uninstall

Scripts receive an action argument. Use `pkg_install`/`pkg_remove` for cross-platform support:

```bash
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install tool-name
    log_success "tool-name installed!"
else
    require_root
    pkg_remove tool-name
fi
```

`pkg_install` automatically uses `apt-get` on Linux and `brew` on macOS, with package name mapping for tools that differ between platforms.

### 5. Test it

```bash
# Check the header parses correctly
ninjamenu --list

# Run the install (Linux)
sudo bash mainmenu/category/your-script.sh

# Run the install (macOS — no sudo)
bash mainmenu/category/your-script.sh

# Verify the check_command works
tool-name --version
```

## Reporting Bugs

Open a GitHub issue with:

- What you expected to happen
- What actually happened
- Your OS and version (`cat /etc/os-release`)
- Any error output

## Submitting Changes

1. **Fork** the repo
2. **Create a branch** for your change: `git checkout -b add-mytool`
3. **Make your changes** following the conventions above
4. **Test** that the menu still works and your script installs correctly
5. **Commit** with a clear message: `git commit -m "Add mytool to network menu"`
6. **Push** to your fork: `git push origin add-mytool`
7. **Open a Pull Request** against `main`

### PR Guidelines

- One tool per PR (makes review easier)
- Include the tool name and category in the PR title
- Briefly describe what the tool does and why it belongs in the menu
- Make sure the YAML header is complete

## Code Style

- Use `#!/bin/bash` shebang
- Use `set -euo pipefail` where appropriate (not required for menu scripts since the menu handles errors)
- Quote variables: `"$VAR"` not `$VAR`
- Use `apt-get` not `apt` in scripts (more reliable for non-interactive use)
- Keep scripts focused — one tool per file

### Cross-Platform Development

NinjaMenu supports both Linux and macOS. **Always use `.lib/platform.sh`** instead of calling package managers directly:

| Instead of... | Use... |
|---------------|--------|
| `apt-get install -y pkg` | `pkg_install pkg` |
| `apt-get remove -y pkg` | `pkg_remove pkg` |
| `apt-get update` | `pkg_update` |
| `sed -i 's/.../' file` | `nt_sed_i 's/.../' file` |
| Manual root check | `require_root` |
| Manual `sed -i` for installed status | `mark_installed true` |

**Available variables** after sourcing platform.sh:
- `$NT_OS` — `"linux"` or `"macos"`
- `$NT_DISTRO` — `"debian"`, `"kali"`, `"ubuntu"`, or `"macos"`
- `$NT_ARCH` — `"x86_64"`, `"arm64"`, `"aarch64"`

**For Linux-only scripts** (Proxmox, XRDP, etc.), add this guard:
```bash
require_linux "This tool requires Linux (Kali/Debian)"
```

**Package name differences** are handled automatically by `pkg_install`. If a package has a different name on macOS (e.g., `zenmap` needs `brew install --cask zenmap`), the mapping is defined in `.lib/platform.sh`.

## Claude Code Skills

This project includes [Claude Code](https://claude.com/claude-code) skills that automate the PR workflow. If you use Claude Code as your development tool, these slash commands are available:

| Skill | What it does |
|-------|-------------|
| `/create-pr` | Scaffold a new feature branch, create files from templates, and open a draft PR |
| `/review-tasks` | Parse code review comments from a PR and create todo tasks for each issue |
| `/approve-pr` | Admin self-approve a specific PR (requires admin credentials) |
| `/merge-pr` | Run pre-merge checks (reviews, CI, conflicts) and merge with strategy choice |

These are defined in `.claude/skills/` and are automatically available when you open the project in Claude Code.

You don't need Claude Code to contribute — the standard fork-and-PR workflow works fine. The skills just speed things up if you have it.

## Questions?

Open an issue on GitHub. We're happy to help.
