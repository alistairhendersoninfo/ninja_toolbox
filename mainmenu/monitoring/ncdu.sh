#!/bin/bash
# ---
# name: "ncdu"
# description: "NCurses disk usage analyzer - find large files interactively"
# type: install
# root: true
# order: 17
# check_command: "ncdu --version"
# tags: "monitoring, disk, usage"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install ncdu
    log_success "ncdu installed!"
else
    require_root
    pkg_remove ncdu
fi
