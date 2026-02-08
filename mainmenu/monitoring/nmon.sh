#!/bin/bash
# ---
# name: "nmon"
# description: "Performance monitor with keyboard shortcuts for different views"
# type: install
# root: true
# order: 21
# check_command: "which nmon"
# tags: "monitoring, performance, interactive"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install nmon
    log_success "nmon installed!"
else
    require_root
    pkg_remove nmon
fi
