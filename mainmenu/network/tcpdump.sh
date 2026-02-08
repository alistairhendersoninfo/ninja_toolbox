#!/bin/bash
# ---
# name: "tcpdump"
# description: "Command-line packet analyzer for network troubleshooting"
# type: install
# root: true
# order: 12
# check_command: "tcpdump --version"
# tags: "network, packet, capture"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install tcpdump
    log_success "tcpdump installed!"
else
    require_root
    pkg_remove tcpdump
fi
