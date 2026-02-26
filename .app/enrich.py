#!/usr/bin/env python3
"""
NinjaMenu Enrichment Engine — populates long_description in meta.yaml files.

Sources tried in order per script:
  1. man page NAME section  (any tool with check_command set)
  2. website meta/og:description  (website field set in meta.yaml)
  3. <binary> --help first non-empty line  (CLI fallback)
  4. skip  (no source available)

After updating all YAML files, rebuilds the SQLite cache.

Usage:
    enrich.py [--force] [--path mainmenu/network/...] [--dry-run]
"""

import argparse
import os
import re
import subprocess
import sys
import urllib.request
import urllib.error
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

APP_DIR = Path(__file__).parent.resolve()
MENU_ROOT = APP_DIR.parent
MAIN_MENU_DIR = MENU_ROOT / "mainmenu"

# ---------------------------------------------------------------------------
# Description sources
# ---------------------------------------------------------------------------

def _from_man(binary: str) -> str:
    """Extract the NAME section from a man page."""
    env = {**os.environ, 'MANPAGER': 'cat', 'MAN_KEEP_FORMATTING': '0',
           'MANWIDTH': '200'}
    try:
        result = subprocess.run(
            ['man', '-P', 'cat', binary],
            capture_output=True, text=True, timeout=5, env=env,
        )
        if result.returncode != 0 or not result.stdout.strip():
            return ''
        # Match the NAME section up to the next all-caps section header
        match = re.search(
            r'\bNAME\b\s*\n(.*?)(?=\n[A-Z][A-Z][A-Z])',
            result.stdout, re.DOTALL,
        )
        if match:
            raw = match.group(1)
            # Collapse whitespace and strip leading dash/hyphen separators
            cleaned = ' '.join(raw.split()).strip()
            cleaned = re.sub(r'^[\w,\s]+ - ', '', cleaned, count=1)
            return cleaned[:500]
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass
    return ''


def _from_website(url: str) -> str:
    """Fetch <meta description> or og:description from a URL."""
    req = urllib.request.Request(
        url,
        headers={'User-Agent': 'Mozilla/5.0 (compatible; NinjaMenu/1.0)'},
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            html = resp.read(65536).decode('utf-8', errors='ignore')
    except (urllib.error.URLError, OSError, Exception):
        return ''

    for pattern in [
        r'<meta\s+name=["\']description["\']\s+content=["\'](.*?)["\']',
        r'<meta\s+content=["\'](.*?)["\']\s+name=["\']description["\']',
        r'<meta\s+property=["\']og:description["\']\s+content=["\'](.*?)["\']',
        r'<meta\s+content=["\'](.*?)["\']\s+property=["\']og:description["\']',
    ]:
        m = re.search(pattern, html, re.IGNORECASE | re.DOTALL)
        if m:
            text = re.sub(r'<[^>]+>', '', m.group(1)).strip()
            # Collapse whitespace and HTML entities
            text = re.sub(r'\s+', ' ', text)
            text = text.replace('&amp;', '&').replace('&lt;', '<') \
                       .replace('&gt;', '>').replace('&#39;', "'") \
                       .replace('&quot;', '"')
            return text[:500]
    return ''


def _from_help(binary: str) -> str:
    """Run <binary> --help and return the first meaningful line."""
    env = os.environ.copy()
    home = os.path.expanduser('~')
    extra = [f"{home}/.local/bin", f"{home}/.cargo/bin",
             f"{home}/.npm-global/bin", "/usr/local/bin", "/opt/homebrew/bin"]
    env['PATH'] = ':'.join(extra) + ':' + env.get('PATH', '')
    try:
        result = subprocess.run(
            [binary, '--help'],
            capture_output=True, text=True, timeout=5, env=env,
        )
        output = result.stdout or result.stderr
        for line in output.splitlines():
            line = line.strip()
            if line and not line.startswith('-') and len(line) > 10:
                return line[:300]
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass
    return ''


def _extract_binary(check_command: str) -> str:
    """Extract the binary name from a check_command string."""
    if not check_command:
        return ''
    # Take the first word before any flags or pipe
    first = check_command.strip().split()[0]
    # Strip any path separators
    return Path(first).name


# ---------------------------------------------------------------------------
# YAML in-place update (no ruamel dependency)
# ---------------------------------------------------------------------------

def _update_yaml_field(meta_path: Path, field: str, value: str, dry_run: bool) -> bool:
    """Insert or replace a field in a YAML meta file.

    Strategy:
    - If a line already starts with '<field>:' → replace it
    - Otherwise → append after the 'description:' line
    Returns True if a change was made (or would be in dry_run).
    """
    if not value:
        return False

    content = meta_path.read_text()
    lines = content.splitlines(keepends=True)

    # Escape any special chars in value for YAML (wrap in quotes if needed)
    needs_quotes = any(c in value for c in (':', '#', '[', ']', '{', '}',
                                             '&', '*', '!', '|', '>', "'",
                                             '"', '%', '@', '`', '\n'))
    if needs_quotes:
        escaped = value.replace('"', '\\"')
        yaml_value = f'"{escaped}"'
    else:
        yaml_value = value

    new_line = f'{field}: {yaml_value}\n'

    # Check if field already exists
    for i, line in enumerate(lines):
        if re.match(rf'^{re.escape(field)}\s*:', line):
            if lines[i] == new_line:
                return False  # Already identical
            if not dry_run:
                lines[i] = new_line
                meta_path.write_text(''.join(lines))
            return True

    # Field not present — insert after 'description:' line
    for i, line in enumerate(lines):
        if re.match(r'^description\s*:', line):
            if not dry_run:
                lines.insert(i + 1, new_line)
                meta_path.write_text(''.join(lines))
            return True

    # Fallback: append at end
    if not dry_run:
        with meta_path.open('a') as f:
            f.write(new_line)
    return True


def _read_yaml_field(meta_path: Path, field: str) -> str:
    """Quick single-field read without full YAML parse."""
    for line in meta_path.read_text().splitlines():
        m = re.match(rf'^{re.escape(field)}\s*:\s*(.+)', line)
        if m:
            val = m.group(1).strip().strip('"\'')
            return val
    return ''

# ---------------------------------------------------------------------------
# Core enrichment logic
# ---------------------------------------------------------------------------

def enrich_meta(meta_path: Path, force: bool, dry_run: bool) -> str:
    """Enrich a single meta.yaml file. Returns a status tag string."""
    existing = _read_yaml_field(meta_path, 'long_description')
    if existing and not force:
        return '[skip]'

    check_command = _read_yaml_field(meta_path, 'check_command')
    website = _read_yaml_field(meta_path, 'website')
    binary = _extract_binary(check_command)

    desc = ''
    source = ''

    # 1. Man page
    if binary:
        desc = _from_man(binary)
        if desc:
            source = '[man]'

    # 2. Website
    if not desc and website:
        desc = _from_website(website)
        if desc:
            source = '[web]'

    # 3. --help fallback
    if not desc and binary:
        desc = _from_help(binary)
        if desc:
            source = '[help]'

    if not desc:
        return '[none]'

    changed = _update_yaml_field(meta_path, 'long_description', desc, dry_run)
    if changed:
        return source
    return '[skip]'  # value was already identical


# ---------------------------------------------------------------------------
# Walk and enrich
# ---------------------------------------------------------------------------

def enrich_all(root: Path, force: bool, dry_run: bool, path_filter: Optional[Path]) -> None:
    """Walk mainmenu/, enrich every meta file, then rebuild the cache."""
    search_root = path_filter if path_filter else root

    # Collect all meta files
    meta_files = []
    for pattern in ('**/*.meta.yaml', '**/meta.yaml'):
        for p in search_root.glob(pattern):
            # Skip hidden/private directories
            if any(part.startswith('.') or part.startswith('_')
                   for part in p.relative_to(root).parts[:-1]):
                continue
            meta_files.append(p)

    meta_files.sort()
    stats = {'man': 0, 'web': 0, 'help': 0, 'skip': 0, 'none': 0}

    for meta_path in meta_files:
        rel = meta_path.relative_to(root)
        name = _read_yaml_field(meta_path, 'name') or meta_path.stem
        status = enrich_meta(meta_path, force=force, dry_run=dry_run)

        tag_key = status.strip('[]')
        stats[tag_key] = stats.get(tag_key, 0) + 1

        marker = '' if status in ('[skip]', '[none]') else ' *'
        dry_tag = ' (dry-run)' if dry_run else ''
        print(f"  {status:7}  {name:<30} {rel}{dry_tag}{marker}")

    print()
    print(f"Results: {stats.get('man',0)} from man, "
          f"{stats.get('web',0)} from web, "
          f"{stats.get('help',0)} from --help, "
          f"{stats.get('skip',0)} skipped, "
          f"{stats.get('none',0)} no source.")

    if not dry_run:
        print("\nRebuilding SQLite cache...")
        sys.path.insert(0, str(APP_DIR))
        from cache import rebuild_cache  # noqa: PLC0415
        db_path = MENU_ROOT / '.cache' / 'menu.db'
        rebuild_cache(root, db_path)
        print(f"Cache rebuilt: {db_path}")


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Enrich meta.yaml long_description from man pages / websites"
    )
    parser.add_argument(
        '--force', action='store_true',
        help='Re-fetch long_description even if already set',
    )
    parser.add_argument(
        '--path', metavar='PATH',
        help='Limit enrichment to a specific subtree (e.g. mainmenu/network)',
    )
    parser.add_argument(
        '--dry-run', action='store_true',
        help='Show what would be updated without writing any files',
    )
    args = parser.parse_args()

    path_filter: Optional[Path] = None
    if args.path:
        candidate = Path(args.path)
        if not candidate.is_absolute():
            candidate = MENU_ROOT / candidate
        if not candidate.exists():
            print(f"Error: path not found: {candidate}", file=sys.stderr)
            sys.exit(1)
        path_filter = candidate

    dry_tag = ' (DRY RUN — no files will be modified)' if args.dry_run else ''
    print(f"==> NinjaMenu Enrichment{dry_tag}")
    print(f"    Root:  {MAIN_MENU_DIR}")
    if path_filter:
        print(f"    Scope: {path_filter}")
    if args.force:
        print("    Mode:  force (re-fetching existing descriptions)")
    print()

    enrich_all(MAIN_MENU_DIR, force=args.force, dry_run=args.dry_run,
               path_filter=path_filter)


if __name__ == '__main__':
    main()
