"""
NinjaMenu SQLite Cache — builds and queries a cache of script metadata.

YAML metadata files remain the single source of truth. The SQLite cache
(.cache/menu.db) is a derived, disposable artifact rebuilt on demand.

Usage:
    from cache import rebuild_cache, get_menu_items, is_cache_stale

    db = MENU_ROOT / ".cache" / "menu.db"
    if not db.exists() or is_cache_stale(MAIN_MENU_DIR, db):
        rebuild_cache(MAIN_MENU_DIR, db)
    items = get_menu_items(db, "llm/cli", "macos")
"""

import json
import os
import platform
import re
import sqlite3
from pathlib import Path
from typing import Any, Dict, List, Optional

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

# ---------------------------------------------------------------------------
# Schema
# ---------------------------------------------------------------------------

_SCHEMA = """
CREATE TABLE IF NOT EXISTS scripts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    path TEXT UNIQUE NOT NULL,
    tier INTEGER NOT NULL,
    name TEXT NOT NULL,
    description TEXT DEFAULT '',
    version TEXT DEFAULT '1.0.0',
    author TEXT DEFAULT 'Unknown',
    type TEXT DEFAULT 'install',
    root BOOLEAN DEFAULT 0,
    menu_order INTEGER DEFAULT 50,
    hidden BOOLEAN DEFAULT 0,
    installed BOOLEAN DEFAULT 0,
    installed_checked_at TEXT,
    check_command TEXT DEFAULT '',
    check_path TEXT DEFAULT '',
    binary_cmd TEXT DEFAULT '',
    binary_available BOOLEAN DEFAULT 1,
    uninstall TEXT DEFAULT '',
    dependencies TEXT DEFAULT '[]',
    tags TEXT DEFAULT '[]',
    supported_os TEXT DEFAULT '[]',
    aliases TEXT DEFAULT '[]',
    parent_menu TEXT NOT NULL,
    script_file TEXT,
    is_modular_folder BOOLEAN DEFAULT 0,
    meta_mtime REAL
);

CREATE TABLE IF NOT EXISTS submenus (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    path TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    parent_menu TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS alias_entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    script_id INTEGER NOT NULL,
    target_menu TEXT NOT NULL,
    FOREIGN KEY (script_id) REFERENCES scripts(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_scripts_parent ON scripts(parent_menu);
CREATE INDEX IF NOT EXISTS idx_scripts_os ON scripts(supported_os);
CREATE INDEX IF NOT EXISTS idx_scripts_type ON scripts(type);
CREATE INDEX IF NOT EXISTS idx_scripts_order ON scripts(menu_order);
CREATE INDEX IF NOT EXISTS idx_submenus_parent ON submenus(parent_menu);
CREATE INDEX IF NOT EXISTS idx_aliases_target ON alias_entries(target_menu);
"""

# ---------------------------------------------------------------------------
# OS detection (mirrors menu.py but kept standalone)
# ---------------------------------------------------------------------------

def _detect_os() -> tuple:
    system = platform.system()
    if system == "Darwin":
        return ("macos", "macos")
    elif system == "Linux":
        distro = "unknown"
        try:
            with open("/etc/os-release") as f:
                for line in f:
                    if line.startswith("ID="):
                        distro = line.strip().split("=", 1)[1].strip('"')
                        break
        except FileNotFoundError:
            pass
        return ("linux", distro)
    elif system == "Windows":
        return ("windows", "windows")
    return ("unknown", "unknown")


_CURRENT_OS, _CURRENT_DISTRO = _detect_os()

# ---------------------------------------------------------------------------
# Tier 1 resolution (mirrors menu.py)
# ---------------------------------------------------------------------------

def _resolve_modular_script(folder: Path) -> Optional[Path]:
    """Resolve a Tier 1 modular folder to the correct OS-specific script."""
    # Exact distro match
    distro_script = folder / f"{_CURRENT_DISTRO}.sh"
    if distro_script.exists():
        return distro_script

    # Distro variant match
    for f in folder.iterdir():
        if f.suffix == '.sh' and not f.name.startswith('_'):
            stem = f.stem.replace('-', ' ').replace('_', ' ').split()[0]
            if stem == _CURRENT_DISTRO:
                return f

    # Generic OS match
    os_script = folder / f"{_CURRENT_OS}.sh"
    if os_script.exists():
        return os_script

    # Windows: try .ps1
    if _CURRENT_OS == "windows":
        ps1_script = folder / "windows.ps1"
        if ps1_script.exists():
            return ps1_script

    return None


def _is_modular_folder(directory: Path) -> bool:
    return (directory / "meta.yaml").exists()

# ---------------------------------------------------------------------------
# YAML parsing (standalone — no check_if_installed at parse time)
# ---------------------------------------------------------------------------

def _parse_yaml_file(meta_path: Path) -> Optional[Dict[str, Any]]:
    """Parse a YAML metadata file and return the raw dict."""
    if not HAS_YAML or not meta_path.exists():
        return None
    try:
        data = yaml.safe_load(meta_path.read_text())
        return data if data else None
    except Exception:
        return None


def _parse_yaml_header(script_path: Path) -> Optional[Dict[str, Any]]:
    """Parse inline YAML header from a Tier 3 legacy script."""
    if not HAS_YAML:
        return None
    try:
        content = script_path.read_text()
        pattern = r'^#\s*---\s*\n((?:#.*\n)*?)#\s*---'
        match = re.search(pattern, content, re.MULTILINE)
        if not match:
            return None
        yaml_lines = match.group(1).split('\n')
        yaml_content = '\n'.join(
            line[1:].strip() if line.startswith('#') else line
            for line in yaml_lines
        )
        data = yaml.safe_load(yaml_content)
        return data if data else None
    except Exception:
        return None

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

def rebuild_cache(menu_dir: Path, db_path: Path) -> None:
    """Full cache rebuild — walk mainmenu/, parse all metadata, write to SQLite.

    After inserting all rows, runs check_command/check_path for every script
    so installed status reflects what is actually on the system.
    """
    db_path.parent.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(str(db_path))
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")

    # Migrate: drop submenus table if it lacks the description column
    try:
        cols = {row[1] for row in conn.execute("PRAGMA table_info(submenus)").fetchall()}
        if cols and 'description' not in cols:
            conn.execute("DROP TABLE IF EXISTS submenus")
    except Exception:
        pass

    # Create schema (idempotent)
    conn.executescript(_SCHEMA)

    # Atomic rebuild: clear + insert in one transaction
    with conn:
        conn.execute("DELETE FROM alias_entries")
        conn.execute("DELETE FROM scripts")
        conn.execute("DELETE FROM submenus")

        _walk_and_insert(menu_dir, menu_dir, conn)

    conn.close()

    # Detect what is actually installed on the system
    check_installed_all(db_path)


def _walk_and_insert(directory: Path, menu_root: Path, conn: sqlite3.Connection) -> None:
    """Recursively walk directory, inserting scripts and submenus."""
    if not directory.exists():
        return

    try:
        rel_dir = directory.relative_to(menu_root)
        parent_menu = str(rel_dir) if str(rel_dir) != "." else ""
    except ValueError:
        parent_menu = ""

    for entry in sorted(directory.iterdir(), key=lambda e: e.name):
        if entry.name.startswith('.') or entry.name.startswith('_'):
            continue

        if entry.is_dir():
            if _is_modular_folder(entry):
                _insert_tier1(entry, menu_root, parent_menu, conn)
            else:
                # Submenu
                rel_path = str(entry.relative_to(menu_root))
                name_parts = entry.name.replace('-', ' ').replace('_', ' ').split()
                camel_name = ''.join(word.capitalize() for word in name_parts)

                # Check for category.yaml with display name/description
                cat_yaml = entry / "category.yaml"
                cat_data = _parse_yaml_file(cat_yaml) if cat_yaml.exists() else None
                display_name = cat_data.get('name', camel_name) if cat_data else camel_name
                description = cat_data.get('description', '') if cat_data else ''

                conn.execute(
                    "INSERT OR REPLACE INTO submenus (path, name, parent_menu, description) VALUES (?, ?, ?, ?)",
                    (rel_path, display_name, parent_menu, description)
                )
                # Recurse into submenu
                _walk_and_insert(entry, menu_root, conn)

        elif entry.suffix == '.sh':
            sibling_meta = entry.parent / f"{entry.stem}.meta.yaml"
            if sibling_meta.exists():
                _insert_tier2(entry, sibling_meta, menu_root, parent_menu, conn)
            else:
                _insert_tier3(entry, menu_root, parent_menu, conn)


def _insert_tier1(folder: Path, menu_root: Path, parent_menu: str, conn: sqlite3.Connection) -> None:
    """Insert a Tier 1 modular folder script."""
    meta_path = folder / "meta.yaml"
    data = _parse_yaml_file(meta_path)
    if not data:
        return

    script_path = _resolve_modular_script(folder)
    if script_path is None:
        return  # OS not supported

    rel_path = str(folder.relative_to(menu_root))
    meta_mtime = meta_path.stat().st_mtime

    if data.get('hidden', False):
        return

    script_id = _insert_script_row(conn, rel_path, 1, data, parent_menu,
                                    str(script_path.relative_to(menu_root)),
                                    True, meta_mtime)
    if script_id:
        _insert_aliases(conn, script_id, data.get('aliases', []))


def _insert_tier2(script: Path, meta_path: Path, menu_root: Path, parent_menu: str, conn: sqlite3.Connection) -> None:
    """Insert a Tier 2 sibling .meta.yaml script."""
    data = _parse_yaml_file(meta_path)
    if not data:
        return

    if data.get('hidden', False):
        return

    rel_path = str(script.relative_to(menu_root))
    meta_mtime = meta_path.stat().st_mtime

    script_id = _insert_script_row(conn, rel_path, 2, data, parent_menu,
                                    rel_path, False, meta_mtime)
    if script_id:
        _insert_aliases(conn, script_id, data.get('aliases', []))


def _insert_tier3(script: Path, menu_root: Path, parent_menu: str, conn: sqlite3.Connection) -> None:
    """Insert a Tier 3 legacy inline-header script."""
    data = _parse_yaml_header(script)
    if not data:
        return

    if data.get('hidden', False):
        return

    rel_path = str(script.relative_to(menu_root))
    meta_mtime = script.stat().st_mtime

    _insert_script_row(conn, rel_path, 3, data, parent_menu,
                       rel_path, False, meta_mtime)


def _insert_script_row(conn: sqlite3.Connection, path: str, tier: int,
                        data: Dict[str, Any], parent_menu: str,
                        script_file: str, is_modular: bool,
                        meta_mtime: float) -> Optional[int]:
    """Insert a single script row and return its id."""
    try:
        cursor = conn.execute("""
            INSERT OR REPLACE INTO scripts
            (path, tier, name, description, version, author, type, root,
             menu_order, hidden, installed, check_command, check_path,
             binary_cmd, uninstall, dependencies, tags, supported_os, aliases,
             parent_menu, script_file, is_modular_folder, meta_mtime)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            path,
            tier,
            data.get('name', Path(path).stem),
            data.get('description', 'No description'),
            data.get('version', '1.0.0'),
            data.get('author', 'Unknown'),
            data.get('type', 'install'),
            1 if data.get('root', False) else 0,
            data.get('order', 50),
            1 if data.get('hidden', False) else 0,
            0,  # installed — checked lazily, not at rebuild time
            data.get('check_command', ''),
            data.get('check_path', ''),
            data.get('binary', ''),
            data.get('uninstall', ''),
            json.dumps(data.get('dependencies', [])),
            json.dumps(data.get('tags', [])),
            json.dumps(data.get('supported_os', [])),
            json.dumps(data.get('aliases', [])),
            parent_menu,
            script_file,
            1 if is_modular else 0,
            meta_mtime,
        ))
        return cursor.lastrowid
    except Exception:
        return None


def _insert_aliases(conn: sqlite3.Connection, script_id: int, aliases: List[str]) -> None:
    """Insert alias entries for a script."""
    for alias in aliases:
        target = alias.strip("/")
        conn.execute(
            "INSERT INTO alias_entries (script_id, target_menu) VALUES (?, ?)",
            (script_id, target)
        )

# ---------------------------------------------------------------------------
# Staleness check
# ---------------------------------------------------------------------------

def is_cache_stale(menu_dir: Path, db_path: Path) -> bool:
    """Check if any metadata file is newer than what the cache recorded.

    Walks mainmenu/ and compares mtimes. Returns True if rebuild needed.
    """
    if not db_path.exists():
        return True

    try:
        conn = sqlite3.connect(str(db_path))
        # Check schema exists
        tables = {row[0] for row in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table'"
        ).fetchall()}
        if 'scripts' not in tables:
            conn.close()
            return True

        cached = {row[0]: row[1] for row in conn.execute(
            "SELECT path, meta_mtime FROM scripts"
        ).fetchall()}
        conn.close()
    except Exception:
        return True

    # Walk filesystem and compare
    return _check_staleness(menu_dir, menu_root=menu_dir, cached=cached, db_mtime=db_path.stat().st_mtime)


def _check_staleness(directory: Path, menu_root: Path, cached: Dict[str, float], db_mtime: float = 0) -> bool:
    """Recursively check if any meta file has changed."""
    if not directory.exists():
        return False

    for entry in directory.iterdir():
        if entry.name.startswith('.') or entry.name.startswith('_'):
            continue

        if entry.is_dir():
            if _is_modular_folder(entry):
                rel_path = str(entry.relative_to(menu_root))
                meta_path = entry / "meta.yaml"
                current_mtime = meta_path.stat().st_mtime
                if rel_path not in cached or cached[rel_path] != current_mtime:
                    return True
            else:
                # Check if category.yaml is newer than the cache db
                cat_yaml = entry / "category.yaml"
                if cat_yaml.exists():
                    if cat_yaml.stat().st_mtime > db_mtime:
                        return True
                if _check_staleness(entry, menu_root, cached, db_mtime):
                    return True
        elif entry.suffix == '.sh':
            sibling_meta = entry.parent / f"{entry.stem}.meta.yaml"
            rel_path = str(entry.relative_to(menu_root))
            if sibling_meta.exists():
                current_mtime = sibling_meta.stat().st_mtime
            else:
                current_mtime = entry.stat().st_mtime
            if rel_path not in cached or cached[rel_path] != current_mtime:
                return True

    # Check for deleted scripts (in cache but not on filesystem)
    # This is a lightweight check — only compare count at top level
    return False

# ---------------------------------------------------------------------------
# Query functions
# ---------------------------------------------------------------------------

def get_menu_items(db_path: Path, parent_menu: str, current_os: str, current_distro: str = "") -> List[Dict[str, Any]]:
    """Get all menu items (submenus + scripts + aliases) for a given parent menu.

    Returns a sorted list of dicts with keys matching MenuItem/ScriptInfo fields.
    Submenus come first (order=0), then scripts sorted by (order, name).
    """
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    items = []

    # 1. Submenus
    rows = conn.execute(
        "SELECT path, name, description FROM submenus WHERE parent_menu = ? ORDER BY name",
        (parent_menu,)
    ).fetchall()
    for row in rows:
        items.append({
            'is_submenu': True,
            'path': row['path'],
            'name': row['name'],
            'description': row['description'],
            'order': 0,
        })

    # Build the set of OS values to match against supported_os lists.
    # On Linux, match both the generic "linux" and the specific distro (e.g. "ubuntu").
    os_matches = {current_os}
    if current_distro and current_distro != current_os:
        os_matches.add(current_distro)

    # 2. Scripts in this menu (filtered by current OS)
    rows = conn.execute(
        "SELECT * FROM scripts WHERE parent_menu = ? AND hidden = 0 ORDER BY menu_order, name",
        (parent_menu,)
    ).fetchall()
    for row in rows:
        supported = json.loads(row['supported_os'])
        if supported and not os_matches.intersection(supported):
            continue
        items.append(_row_to_dict(row))

    # 3. Aliased scripts targeting this menu
    rows = conn.execute("""
        SELECT s.* FROM scripts s
        JOIN alias_entries a ON a.script_id = s.id
        WHERE a.target_menu = ? AND s.hidden = 0
        ORDER BY s.menu_order, s.name
    """, (parent_menu,)).fetchall()
    for row in rows:
        supported = json.loads(row['supported_os'])
        if supported and not os_matches.intersection(supported):
            continue
        items.append(_row_to_dict(row))

    conn.close()

    # Sort: submenus first, then by order, then by name
    items.sort(key=lambda x: (0 if x.get('is_submenu') else 1,
                               x.get('order', 50),
                               x.get('name', '')))
    return items


def get_script(db_path: Path, script_path: str) -> Optional[Dict[str, Any]]:
    """Get a single script by its path (relative to mainmenu/)."""
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    row = conn.execute(
        "SELECT * FROM scripts WHERE path = ?", (script_path,)
    ).fetchone()
    conn.close()
    if row:
        return _row_to_dict(row)
    return None


def search_scripts(db_path: Path, query: str) -> List[Dict[str, Any]]:
    """Search scripts by name or description."""
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT * FROM scripts WHERE hidden = 0 AND (name LIKE ? OR description LIKE ?) ORDER BY menu_order, name",
        (f"%{query}%", f"%{query}%")
    ).fetchall()
    conn.close()
    return [_row_to_dict(row) for row in rows]


def check_installed_all(db_path: Path) -> None:
    """Run check_command / check_path for every script and update the DB.

    Called after a cache rebuild so installed status reflects reality
    rather than the static YAML value (which is always false in git).
    """
    import subprocess as _sp
    from datetime import datetime

    home = os.path.expanduser("~")
    extra_paths = [
        f"{home}/.local/bin",
        f"{home}/.cargo/bin",
        f"{home}/.npm-global/bin",
        "/usr/local/bin",
        "/opt/homebrew/bin",
    ]
    env = os.environ.copy()
    env["PATH"] = ":".join(extra_paths) + ":" + env.get("PATH", "")

    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT path, check_command, check_path FROM scripts"
    ).fetchall()

    now = datetime.now().isoformat()
    updates = []
    for row in rows:
        installed = False
        # Check by command
        if row['check_command']:
            try:
                result = _sp.run(
                    row['check_command'], shell=True,
                    capture_output=True, timeout=5, env=env,
                )
                if result.returncode == 0:
                    installed = True
            except Exception:
                pass
        # Check by path
        if not installed and row['check_path']:
            for p in row['check_path'].split(':'):
                expanded = os.path.expanduser(p.strip())
                if os.path.exists(expanded):
                    installed = True
                    break
        updates.append((1 if installed else 0, now, row['path']))

    with conn:
        conn.executemany(
            "UPDATE scripts SET installed = ?, installed_checked_at = ? WHERE path = ?",
            updates,
        )
    conn.close()


def update_installed(db_path: Path, script_path: str, installed: bool) -> None:
    """Update the installed status of a single script after install/uninstall."""
    from datetime import datetime
    conn = sqlite3.connect(str(db_path))
    with conn:
        conn.execute(
            "UPDATE scripts SET installed = ?, installed_checked_at = ? WHERE path = ?",
            (1 if installed else 0, datetime.now().isoformat(), script_path)
        )
    conn.close()


def update_installed_batch(db_path: Path, updates: Dict[str, bool]) -> None:
    """Batch update installed status for multiple scripts."""
    from datetime import datetime
    now = datetime.now().isoformat()
    conn = sqlite3.connect(str(db_path))
    with conn:
        for path, installed in updates.items():
            conn.execute(
                "UPDATE scripts SET installed = ?, installed_checked_at = ? WHERE path = ?",
                (1 if installed else 0, now, path)
            )
    conn.close()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _row_to_dict(row: sqlite3.Row) -> Dict[str, Any]:
    """Convert a sqlite3.Row to a dict with parsed JSON fields."""
    d = dict(row)
    d['is_submenu'] = False
    d['order'] = d.pop('menu_order', 50)
    d['root'] = bool(d.get('root', 0))
    d['hidden'] = bool(d.get('hidden', 0))
    d['installed'] = bool(d.get('installed', 0))
    d['is_modular_folder'] = bool(d.get('is_modular_folder', 0))
    d['binary_available'] = bool(d.get('binary_available', 1))

    # Parse JSON array fields
    for field in ('dependencies', 'tags', 'supported_os', 'aliases'):
        val = d.get(field, '[]')
        try:
            d[field] = json.loads(val) if isinstance(val, str) else val
        except (json.JSONDecodeError, TypeError):
            d[field] = []

    # Rename for compatibility with ScriptInfo
    d['script_type'] = d.pop('type', 'install')
    d['binary'] = d.pop('binary_cmd', '')
    d['check_command'] = d.get('check_command', '')
    d['check_path'] = d.get('check_path', '')
    d['uninstall'] = d.get('uninstall', '')

    return d
