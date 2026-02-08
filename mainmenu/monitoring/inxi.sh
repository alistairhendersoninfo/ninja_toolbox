#!/bin/bash
# ---
# name: "inxi"
# description: "Full system information tool - hardware, software, network"
# type: install
# root: true
# order: 19
# check_command: "inxi --version"
# tags: "monitoring, system, info"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install inxi
    log_success "inxi installed!"
else
    require_root
    pkg_remove inxi
fi
