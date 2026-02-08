#!/bin/bash
# ---
# name: "net-tools (netstat, ifconfig)"
# description: "Classic network utilities - netstat, ifconfig, route, arp"
# type: install
# root: true
# order: 19
# check_command: "netstat --version"
# tags: "network, legacy, utilities"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install net-tools
    log_success "net-tools installed!"
else
    require_root
    pkg_remove net-tools
fi
