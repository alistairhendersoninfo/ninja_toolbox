#!/bin/bash
# ---
# name: "vnstat"
# description: "Network traffic monitor with daily/monthly statistics"
# type: install
# root: true
# order: 21
# check_command: "vnstat --version"
# tags: "network, traffic, statistics"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install vnstat
    systemctl enable vnstat 2>/dev/null || true
    log_success "vnstat installed!"
else
    require_root
    pkg_remove vnstat
fi
