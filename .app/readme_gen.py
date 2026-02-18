"""
NinjaMenu README Generator — auto-updates README.md from SQLite cache data.

Replaces content between marker comments with fresh data:
  <!-- AUTO:WHATS_INCLUDED --> ... <!-- /AUTO:WHATS_INCLUDED -->
  <!-- AUTO:ADDING_SCRIPTS --> ... <!-- /AUTO:ADDING_SCRIPTS -->

Usage:
    python3 .app/readme_gen.py                 # Update README.md in place
    python3 .app/readme_gen.py --dry-run       # Print generated content to stdout
    python3 .app/readme_gen.py --check-only    # Exit 0 if current, 1 if stale
    python3 .app/readme_gen.py --readme PATH   # Use a different README path
"""

import argparse
import re
import sqlite3
import sys
from pathlib import Path

# Resolve project root (parent of .app/)
APP_DIR = Path(__file__).resolve().parent
REPO_ROOT = APP_DIR.parent
MAIN_MENU_DIR = REPO_ROOT / "mainmenu"
DB_PATH = REPO_ROOT / ".cache" / "menu.db"
DEFAULT_README = REPO_ROOT / "README.md"

# Import cache module for staleness check / rebuild
sys.path.insert(0, str(APP_DIR))
from cache import rebuild_cache, is_cache_stale


def ensure_cache_fresh() -> None:
    """Rebuild the cache if stale or missing."""
    if not DB_PATH.exists() or is_cache_stale(MAIN_MENU_DIR, DB_PATH):
        rebuild_cache(MAIN_MENU_DIR, DB_PATH)


def generate_whats_included() -> str:
    """Generate the What's Included markdown table from SQLite cache."""
    conn = sqlite3.connect(str(DB_PATH))

    # Get top-level categories
    categories = conn.execute(
        "SELECT path, name, description FROM submenus WHERE parent_menu = '' ORDER BY name"
    ).fetchall()

    # Count scripts recursively under each top-level category
    rows = []
    total = 0
    for cat_path, cat_name, cat_desc in categories:
        count = conn.execute(
            "SELECT COUNT(*) FROM scripts WHERE hidden = 0 AND (parent_menu = ? OR parent_menu LIKE ?)",
            (cat_path, f"{cat_path}/%")
        ).fetchone()[0]
        rows.append((cat_name, cat_desc, count))
        total += count

    conn.close()

    lines = [
        f"**{total} scripts** across {len(rows)} categories, with more being added regularly.",
        "",
        "| Category | Description | Scripts |",
        "|----------|-------------|:-------:|",
    ]
    for name, desc, count in rows:
        lines.append(f"| {name} | {desc} | {count} |")

    return "\n".join(lines)


def generate_adding_scripts() -> str:
    """Generate the Adding Your Own Scripts section with Tier 2 workflow."""
    return """Create a `.sh` script and a matching `.meta.yaml` file in any category folder:

```bash
# mainmenu/monitoring/mytool.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_install mytool
else
    require_root
    pkg_remove mytool
fi
```

```yaml
# mainmenu/monitoring/mytool.meta.yaml
name: "My Tool"
description: "What it does in one line"
type: install
root: true
order: 50
check_command: "mytool --version"
tags:
  - monitoring
supported_os:
  - macos
  - kali
  - debian
  - ubuntu
```

That's it. Your script appears in the menu with install status detection. `pkg_install` uses `apt-get` on Linux and `brew` on macOS automatically.

### Key Fields

| Field | Purpose |
|-------|---------|
| `name` | Display name in menu |
| `description` | Shows in detail view |
| `type` | `install`, `config` (run-only), or `tool` (requires binary) |
| `root` | `true` if needs sudo |
| `order` | Sort position (lower = higher) |
| `check_command` | How to verify it's installed |
| `check_path` | Alternative: check if path exists |
| `supported_os` | `macos`, `kali`, `debian`, `ubuntu` |
| `binary` | Required command for `tool` type scripts |

For multi-OS scripts, Tier 1 modular folders, and full guidelines see the [Contributing Guide](mainmenu/CONTRIBUTING.md)."""


def replace_section(text: str, marker: str, content: str) -> str:
    """Replace content between <!-- AUTO:marker --> and <!-- /AUTO:marker -->."""
    pattern = rf"(<!-- AUTO:{marker} -->\n).*?(<!-- /AUTO:{marker} -->)"
    replacement = rf"\1{content}\n\2"
    result, count = re.subn(pattern, replacement, text, flags=re.DOTALL)
    if count == 0:
        print(f"WARNING: Marker AUTO:{marker} not found in README", file=sys.stderr)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Auto-update README.md from SQLite cache")
    parser.add_argument("--readme", type=Path, default=DEFAULT_README, help="Path to README.md")
    parser.add_argument("--dry-run", action="store_true", help="Print generated content to stdout")
    parser.add_argument("--check-only", action="store_true", help="Exit 0 if current, 1 if stale")
    args = parser.parse_args()

    ensure_cache_fresh()

    whats_included = generate_whats_included()
    adding_scripts = generate_adding_scripts()

    if args.dry_run:
        print("=== WHATS_INCLUDED ===")
        print(whats_included)
        print()
        print("=== ADDING_SCRIPTS ===")
        print(adding_scripts)
        return 0

    readme_text = args.readme.read_text()

    updated = replace_section(readme_text, "WHATS_INCLUDED", whats_included)
    updated = replace_section(updated, "ADDING_SCRIPTS", adding_scripts)

    if args.check_only:
        if updated == readme_text:
            print("README is up to date.")
            return 0
        else:
            print("README is outdated — run readme_gen.py to update.")
            return 1

    if updated == readme_text:
        print("README is already up to date.")
        return 0

    args.readme.write_text(updated)
    print(f"README updated: {args.readme}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
