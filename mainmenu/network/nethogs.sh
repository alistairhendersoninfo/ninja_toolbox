#!/bin/bash
# ---
# name: "nethogs"
# description: "Monitor bandwidth usage per process in real-time"
# type: install
# root: true
# order: 16
# check_command: "which nethogs"
# tags: "network, bandwidth, per-process"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install nethogs
    log_success "nethogs installed!"
else
    require_root
    pkg_remove nethogs
fi
