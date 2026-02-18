#!/bin/bash
# ninja-readme.sh — Auto-update README.md from SQLite cache data
# Usage: ninja-readme.sh [--dry-run | --check-only]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Activate venv
if [[ -d "$REPO_ROOT/.venv" ]]; then
    source "$REPO_ROOT/.venv/bin/activate"
fi

# Rebuild cache first (ensures data is current)
echo "==> Rebuilding menu cache..."
python3 "$REPO_ROOT/.app/menu.py" --rebuild

if [[ $? -ne 0 ]]; then
    echo "ERROR: Cache rebuild failed"
    exit 1
fi

# Run README generator
echo "==> Updating README.md..."
python3 "$REPO_ROOT/.app/readme_gen.py" "$@"
exit_code=$?

if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    deactivate 2>/dev/null || true
fi

exit $exit_code
