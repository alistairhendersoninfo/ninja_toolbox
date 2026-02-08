#!/bin/bash
# ---
# name: "nmap-unleashed"
# description: "Enhanced Nmap wrapper with automated scanning and reporting"
# type: install
# root: false
# order: 12
# check_command: "nu --help"
# tags: "network, scanner, nmap, automation"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install xsltproc pipx
    pipx ensurepath
    pipx install "git+https://github.com/Sharkeonix/nmap-unleashed.git"
    log_success "nmap-unleashed installed! Run with: nu --help"
    log_info "Open a new terminal if 'nu' is not found (pipx PATH update)."
else
    pipx uninstall nmap-unleashed
fi
