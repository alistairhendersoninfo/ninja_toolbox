#!/bin/bash
# ninja-enrich.sh — Enrich meta.yaml long_description from man pages / websites
# Usage: ninja-enrich.sh [--force] [--path mainmenu/...] [--dry-run]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Activate venv if present
if [[ -d "$REPO_ROOT/.venv" ]]; then
    source "$REPO_ROOT/.venv/bin/activate"
fi

python3 "$REPO_ROOT/.app/enrich.py" "$@"
EXIT_CODE=$?

if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    deactivate 2>/dev/null || true
fi

exit $EXIT_CODE
