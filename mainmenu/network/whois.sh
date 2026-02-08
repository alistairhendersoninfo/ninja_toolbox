#!/bin/bash
# ---
# name: "whois"
# description: "Query domain registration and IP ownership information"
# type: install
# root: true
# order: 22
# check_command: "whois --version"
# tags: "network, dns, lookup"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install whois
    log_success "whois installed!"
else
    require_root
    pkg_remove whois
fi
