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

### 3. Support install and uninstall

Scripts receive an action argument. Handle both:

```bash
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y tool-name
    echo "tool-name installed! Run with: tool-name"
else
    apt-get remove -y tool-name && apt-get autoremove -y
fi
```

### 4. Test it

```bash
# Check the header parses correctly
ninjamenu --list

# Run the install
sudo bash mainmenu/category/your-script.sh

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
