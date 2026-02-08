#!/bin/bash
# ---
# name: "btop"
# description: "Modern resource monitor with beautiful graphs and themes"
# type: install
# root: true
# order: 11
# check_command: "btop --version"
# tags: "monitoring, modern, beautiful"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install btop
    log_success "btop installed!"
else
    require_root
    pkg_remove btop
fi
