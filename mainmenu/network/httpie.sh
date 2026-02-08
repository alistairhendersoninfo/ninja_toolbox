#!/bin/bash
# ---
# name: "httpie"
# description: "User-friendly HTTP client with JSON support and syntax highlighting"
# type: install
# root: true
# order: 23
# check_command: "http --version"
# tags: "network, http, client"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install httpie
    log_success "httpie installed!"
else
    require_root
    pkg_remove httpie
fi
