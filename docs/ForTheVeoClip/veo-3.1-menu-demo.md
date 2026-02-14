# NinjaMenu — Video Generation Prompt (Gemini Veo 3.1)

## What This Is

NinjaMenu is a terminal-based menu system that turns a folder structure into a fully navigable, interactive TUI (Text User Interface). You drop shell scripts into folders, add a small YAML header to each script, and the menu builds itself. No config files. No databases. No manual wiring. Folders become menus. Subfolders become submenus. Scripts become selectable items — complete with names, descriptions, install status, and keyboard shortcuts.

80 scripts across 8 categories, navigable from a single command: `./menu.py`

---

## How the Menu Looks (Visual Description for Video)

The menu runs inside a terminal emulator (dark background, monospace font). It has three visual backends that can be switched via a config file:

### Primary Look — gum (Charm.sh)

A modern, minimal terminal UI with:

- A **bordered header box** at the top with rounded corners in purple, showing the breadcrumb path: `Main Menu > Network > Nmap > Scanning`
- Below it, a **filterable list** of menu items, each prefixed with a zero-padded number
- Folder items show a folder icon: `01. [folder] Network`
- Script items show install status: `02. [checkmark] nmap` or `02. [empty box] nmap`
- Root-required scripts show a lock icon
- Tool scripts (that run rather than install) show a play icon
- At the bottom: `b. Back` and `x. Exit`
- Typing a number or letter instantly filters/selects
- Purple borders, pink highlighted matches, grey prompt text — all configurable via a settings file

### Secondary Look — Textual (Python Rich TUI)

A full-screen application with:

- A **header bar** at the very top showing `NinjaMenu` and a clock
- A **breadcrumb bar** below: `Main Menu > LLM > CLI`
- A **scrollable option list** in the centre with highlight bar that moves with arrow keys
- A **detail panel** docked at the bottom showing the description, version, status, and tags of the currently highlighted item
- A **footer bar** with key bindings: `q Quit | Esc Back | r Refresh | i Install | u Uninstall`
- Full keyboard navigation: arrow keys, Enter to select, Escape to go back, number keys to jump

### Tertiary Look — whiptail (Classic ncurses)

A retro dialog-box style:

- Classic blue/grey ncurses modal dialog centered on screen
- Numbered list of items with arrow-key navigation
- Title bar shows breadcrumb path
- OK/Cancel buttons at the bottom

---

## The Core Concept: Folders = Menus

The entire menu is generated at runtime by scanning a single directory tree. There is no menu configuration file. The filesystem IS the configuration.

### The Folder Tree

```
mainmenu/                          <-- Root menu
  education/                       <-- "Education" submenu
    network/                       <--   "Network" submenu
      nmap/                        <--     "Nmap" submenu
        scanning/                  <--       "Scanning" submenu
          quick-scan.sh            <--         Menu item: "Quick Scan"
          full-port-scan.sh        <--         Menu item: "Full Port Scan"
          stealth-syn-scan.sh      <--         Menu item: "Stealth SYN Scan"
          ping-sweep.sh            <--         Menu item: "Ping Sweep"
          udp-scan.sh              <--         Menu item: "UDP Scan"
          specific-ports.sh        <--         Menu item: "Specific Ports"
        discovery/                 <--       "Discovery" submenu
          dns-brute.sh
          smb-enum.sh
          snmp-enum.sh
          broadcast-discovery.sh
        evasion/                   <--       "Evasion" submenu
          decoy-scan.sh
          fragment-scan.sh
          idle-scan.sh
          slow-scan.sh
        footprinting/              <--       "Footprinting" submenu
        output/                    <--       "Output" submenu
        vulnerability/             <--       "Vulnerability" submenu
      nmap-unleashed/              <--     "NmapUnleashed" submenu
        scanning/
        reporting/
  git/                             <-- "Git" submenu
    git-setup.sh
    push-to-repo.sh
    reset-credentials.sh
    test-connection.sh
  llm/                             <-- "Llm" submenu
    claude/                        <--   "Claude" submenu
      claude-code.sh
      install-skills.sh
    cli/                           <--   "Cli" submenu
      claude-cli.sh
      codex-cli.sh
      gemini-cli.sh
    ide/                           <--   "Ide" submenu
      cursor.sh
      antigravity.sh
  monitoring/                      <-- "Monitoring" submenu (12 tools)
  network/                         <-- "Network" submenu (15 tools)
  postsetup-kali/                  <-- "PostsetupKali" submenu
  proxmox/                         <-- "Proxmox" submenu
```

### The Rules

| What you create | What the menu shows |
|---|---|
| A **folder** inside `mainmenu/` | A **submenu** entry with a folder icon |
| A **subfolder** inside that folder | A **nested submenu** (unlimited depth) |
| A **`.sh` script** inside any folder | A **selectable menu item** |
| A **dot-prefixed** folder (`.hidden/`) | **Nothing** — hidden from the menu |
| A **YAML header** inside the script | The item's **name, description, status, and metadata** |

Adding a new category is: `mkdir mainmenu/my-new-category/`
Adding a new tool is: drop a `.sh` file into any folder.
No code changes. No menu rebuilds. The menu discovers everything on launch.

---

## YAML Headers: The Metadata Engine

Every script contains a YAML block between `# ---` markers at the top. This is what turns a raw shell script into a rich menu item.

### Example: A Simple Install Script

```bash
#!/bin/bash
# ---
# name: "btop"
# description: "Modern resource monitor with beautiful graphs and themes"
# type: install
# root: true
# order: 11
# check_command: "btop --version"
# tags: "monitoring, modern, beautiful"
# ---

# ... installation logic below ...
```

**What the menu sees:**
- Display name: **btop**
- Description shown in detail panel: **Modern resource monitor with beautiful graphs and themes**
- Type `install` means it shows Install/Uninstall actions
- Lock icon appears because `root: true`
- Sorted by `order: 11` within its folder
- Status is auto-detected by running `btop --version` — if it succeeds, the checkmark icon shows

### Example: A Full-Featured Install Script

```bash
#!/bin/bash
# ---
# name: "Claude CLI"
# description: "Anthropic's official CLI for Claude AI"
# version: "1.0.0"
# author: "Anthropic"
# root: false
# order: 10
# check_command: "claude --version"
# check_path: "~/.local/bin/claude"
# dependencies:
#   - curl
# tags:
#   - llm
#   - cli
#   - anthropic
# ---
```

**What the menu sees:**
- No lock icon (root: false)
- Checks both command AND file path to detect installation
- Dependencies listed for reference
- Tags for categorization

### Example: A Tool Script (Run, Don't Install)

```bash
#!/bin/bash
# ---
# name: "Stealth SYN Scan"
# description: "Half-open SYN scan that doesn't complete TCP handshake"
# type: tool
# root: true
# order: 40
# binary: "nmap"
# tags: "network, scanning, nmap, stealth"
# ---
```

**What the menu sees:**
- Type `tool` means it shows a Run action (play icon), not Install/Uninstall
- `binary: "nmap"` tells the menu to check if nmap is installed first
- If nmap is missing, the item shows a blocked icon and can't be run
- If nmap is present, the item shows a play icon and is ready to execute

### The Three Script Types

| Type | Icon | Actions | Purpose |
|---|---|---|---|
| `install` | Checkmark or empty box | Install / Uninstall | Software that gets installed on the system |
| `config` | Gear | Run | Configuration utilities, one-time setup scripts |
| `tool` | Play or blocked | Run (if binary available) | Tools that use an already-installed binary |

### YAML Field Reference

| Field | What It Controls |
|---|---|
| `name` | Display name in the menu |
| `description` | Detail text shown when item is highlighted |
| `type` | Script behaviour: `install`, `config`, or `tool` |
| `root` | Whether the lock icon appears and sudo is used |
| `order` | Sort position within the folder (lower = higher) |
| `check_command` | Command run to detect if already installed |
| `check_path` | File path checked to detect if already installed |
| `binary` | Required binary for tool scripts (checked at runtime) |
| `hidden` | If true, the script is invisible in the menu |
| `tags` | Categorization labels |
| `dependencies` | Required packages |
| `version` | Version string shown in detail panel |

---

## What the User Experiences (Demo Walkthrough)

### Scene 1: Launch

The user opens a terminal and types:

```
./menu.py
```

The menu appears instantly. A bordered header shows `Main Menu`. Below it, 8 categories are listed:

```
  01. [folder] Education
  02. [folder] Git
  03. [folder] Llm
  04. [folder] Monitoring
  05. [folder] Network
  06. [folder] PostsetupKali
  07. [folder] Proxmox
  ──────────────────────────────
  x. Exit
```

### Scene 2: Navigating Into a Category

The user types `05` or arrows down to Network and presses Enter. The breadcrumb updates:

```
  Main Menu > Network
```

15 network tools are listed with their install status:

```
  01. [checkmark][lock] nmap
  02. [empty][lock]     arp-scan
  03. [checkmark]       httpie
  04. [empty][lock]     masscan
  05. [checkmark]       mtr
  ...
  15. [empty][lock]     zenmap
  ──────────────────────────────
  b. Back
  x. Exit
```

Green checkmarks for installed tools. Empty boxes for uninstalled. Lock icons for tools that need root.

### Scene 3: Selecting a Script

The user selects nmap. A detail panel appears:

```
  ╭─────────────────────────────────────╮
  │ nmap                                │
  │                                     │
  │ Description: Network scanner for    │
  │   port discovery and security       │
  │   auditing                          │
  │ Version: 1.0.0                      │
  │ Requires Root: Yes                  │
  │ Installed: Yes                      │
  ╰─────────────────────────────────────╯

  i. Install
  u. Uninstall
  l. View Log
  v. View Script
  b. Back
```

### Scene 4: Deep Nesting

The user navigates: `Education > Network > Nmap > Scanning`

The breadcrumb reads: `Main Menu > Education > Network > Nmap > Scanning`

Six scanning tools appear — all type `tool`, all requiring the nmap binary:

```
  01. [play][lock]  Stealth SYN Scan
  02. [play]        Quick Scan
  03. [play]        Full Port Scan
  04. [play][lock]  Ping Sweep
  05. [play][lock]  UDP Scan
  06. [play]        Specific Ports
  ──────────────────────────────────────
  b. Back
  x. Exit
```

The user selects "Stealth SYN Scan". Because `binary: "nmap"` is set and nmap IS installed, the script runs. It prompts for a target IP, then executes `nmap -sS` and displays the results.

### Scene 5: Adding a New Tool (Zero Code Changes)

To add a brand new category and tool, the user does:

```bash
mkdir mainmenu/databases/
```

Then drops a script file `mainmenu/databases/postgresql.sh` with a YAML header:

```bash
#!/bin/bash
# ---
# name: "PostgreSQL"
# description: "Install PostgreSQL database server"
# type: install
# root: true
# order: 10
# check_command: "psql --version"
# ---
sudo apt install postgresql -y
```

Next time the menu launches, "Databases" appears as a new top-level category with PostgreSQL inside it. No other files were touched.

---

## Technology Stack

| Layer | Technology | Role |
|---|---|---|
| Menu engine | **Python 3** | Scans folders, parses YAML, routes to TUI backend |
| Primary TUI | **gum** (Charm.sh) | Beautiful terminal styling, filtered selection lists |
| Rich TUI | **Textual** (Python) | Full-screen app with panels, key bindings, mouse support |
| Fallback TUI | **whiptail** | Classic ncurses dialogs for minimal environments |
| Script metadata | **YAML** (in bash comments) | Name, description, type, status, dependencies |
| Scripts | **Bash** | The actual installation/tool/config logic |
| Auto-detection | `check_command` / `check_path` | Determines install status at runtime |

---

## Key Selling Points for Video

1. **Zero-config menus** — The folder structure IS the menu. No JSON. No database. No manifest.
2. **Drop-in extensibility** — Add a folder, get a submenu. Add a script, get a menu item. Instantly.
3. **Smart status detection** — The menu checks in real-time whether each tool is installed by running its `check_command`.
4. **Three script types** — Install tools, run configs, or launch pre-installed binaries — all from the same menu.
5. **Unlimited nesting** — `education/network/nmap/scanning/` is 4 levels deep and the breadcrumb tracks every level.
6. **80 scripts, 8 categories** — A real-world toolkit covering monitoring, networking, LLMs, git, proxmox, and education.
7. **3 visual backends** — Switch between modern (gum), rich (Textual), or classic (whiptail) with a single config line.
8. **Keyboard-first** — Number keys to jump, letters for shortcuts, arrow keys to browse, Escape to go back.
9. **YAML-powered metadata** — Every script declares its own name, description, type, root requirement, sort order, and installation detection — all in 10 lines of commented YAML.
10. **Runs anywhere** — Linux and macOS. Kali, Ubuntu, Debian, Arch, or Homebrew on Mac.
