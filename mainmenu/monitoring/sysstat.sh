#!/bin/bash
# ---
# name: "sysstat (sar, iostat)"
# description: "System performance tools for CPU, memory, I/O statistics"
# type: install
# root: true
# order: 20
# check_command: "sar -V"
# tags: "monitoring, performance, statistics"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install sysstat
    log_success "sysstat installed!"
else
    require_root
    pkg_remove sysstat
fi
