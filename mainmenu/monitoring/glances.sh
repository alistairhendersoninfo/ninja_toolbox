#!/bin/bash
# ---
# name: "glances"
# description: "Cross-platform system monitor with web interface support"
# type: install
# root: true
# order: 15
# check_command: "glances --version"
# tags: "monitoring, all-in-one, web"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install glances
    log_success "glances installed!"
else
    require_root
    pkg_remove glances
fi
