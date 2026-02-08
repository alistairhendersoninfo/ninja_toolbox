#!/bin/bash
# ---
# name: "netcat (nc)"
# description: "TCP/UDP Swiss Army knife - read/write network connections"
# type: install
# root: true
# order: 14
# check_command: "nc -h"
# tags: "network, connection, swiss-army"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install netcat-openbsd
    log_success "netcat-openbsd installed!"
else
    require_root
    pkg_remove netcat-openbsd
fi
