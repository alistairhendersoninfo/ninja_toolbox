#!/bin/bash
# ---
# name: "atop"
# description: "Advanced system monitor with logging and historical playback"
# type: install
# root: true
# order: 12
# check_command: "atop -V"
# tags: "monitoring, advanced, logging"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install atop
    log_success "atop installed!"
else
    require_root
    pkg_remove atop
fi
