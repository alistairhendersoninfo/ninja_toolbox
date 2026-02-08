#!/bin/bash
# ---
# name: "iotop"
# description: "Monitor disk I/O usage by process in real-time"
# type: install
# root: true
# order: 13
# check_command: "iotop --version"
# tags: "monitoring, io, disk"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install iotop
    log_success "iotop installed!"
else
    require_root
    pkg_remove iotop
fi
