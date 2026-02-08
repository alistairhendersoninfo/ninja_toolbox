#!/bin/bash
# ---
# name: "nmap"
# description: "Network scanner for port discovery and security auditing"
# type: install
# root: true
# order: 10
# check_command: "nmap --version"
# tags: "network, scanner, security"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install nmap
    log_success "nmap installed!"
else
    require_root
    pkg_remove nmap
fi
