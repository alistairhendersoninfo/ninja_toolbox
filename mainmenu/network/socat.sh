#!/bin/bash
# ---
# name: "socat"
# description: "Multipurpose relay for bidirectional data transfer"
# type: install
# root: true
# order: 20
# check_command: "socat -V"
# tags: "network, relay, multipurpose"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install socat
    log_success "socat installed!"
else
    require_root
    pkg_remove socat
fi
