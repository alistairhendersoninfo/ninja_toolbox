#!/bin/bash
# ---
# name: "wireshark"
# description: "GUI and CLI packet analyzer for deep network inspection"
# type: install
# root: true
# order: 13
# check_command: "wireshark --version"
# tags: "network, packet, gui"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install wireshark tshark
    log_success "wireshark installed!"
else
    require_root
    pkg_remove wireshark tshark
fi
