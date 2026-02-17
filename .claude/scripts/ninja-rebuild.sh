#!/bin/bash
# ninja-rebuild.sh — Rebuild the SQLite menu cache from YAML metadata
# Usage: ninja-rebuild.sh [--check-installed]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Activate venv
if [[ -d "$REPO_ROOT/.venv" ]]; then
    source "$REPO_ROOT/.venv/bin/activate"
fi

# Rebuild cache
echo "==> Rebuilding menu cache..."
python3 "$REPO_ROOT/.app/menu.py" --rebuild

if [[ $? -ne 0 ]]; then
    echo "ERROR: Cache rebuild failed"
    exit 1
fi

# Optionally check installed status for all scripts
if [[ "${1:-}" == "--check-installed" ]]; then
    echo ""
    echo "==> Checking installed status for all scripts..."
    echo "    (This runs check_command for each script — may take a while)"

    # Use Python to run check_if_installed for each cached script
    python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/.app')
from cache import *
from menu import check_if_installed, ScriptInfo, MAIN_MENU_DIR
import sqlite3, json

db = '$REPO_ROOT/.cache/menu.db'
conn = sqlite3.connect(db)
conn.row_factory = sqlite3.Row
rows = conn.execute('SELECT * FROM scripts WHERE check_command != \"\" OR check_path != \"\"').fetchall()
conn.close()

updates = {}
for row in rows:
    info = ScriptInfo(
        path=MAIN_MENU_DIR / (row['script_file'] or row['path']),
        check_command=row['check_command'],
        check_path=row['check_path'],
        installed=bool(row['installed']),
    )
    result = check_if_installed(info)
    updates[row['path']] = result
    status = 'installed' if result else 'not installed'
    print(f'    {row[\"name\"]}: {status}')

from pathlib import Path
update_installed_batch(Path(db), updates)
print(f'\n    Checked {len(updates)} scripts.')
"
fi

# Report stats
python3 -c "
import sqlite3
db = '$REPO_ROOT/.cache/menu.db'
conn = sqlite3.connect(db)
scripts = conn.execute('SELECT COUNT(*) FROM scripts').fetchone()[0]
submenus = conn.execute('SELECT COUNT(*) FROM submenus').fetchone()[0]
aliases = conn.execute('SELECT COUNT(*) FROM alias_entries').fetchone()[0]
conn.close()
print(f'\nCache rebuilt. {scripts} scripts, {submenus} submenus, {aliases} alias entries.')
"

if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    deactivate 2>/dev/null || true
fi
