#!/bin/bash
# ---
# name: "duf"
# description: "Modern disk usage utility with colorful output"
# type: install
# root: true
# order: 18
# check_command: "duf --version"
# tags: "monitoring, disk, modern"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install duf
    log_success "duf installed!"
else
    require_root
    pkg_remove duf
fi
