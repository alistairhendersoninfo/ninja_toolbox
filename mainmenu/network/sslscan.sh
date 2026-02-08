#!/bin/bash
# ---
# name: "sslscan"
# description: "Test SSL/TLS enabled services for security vulnerabilities"
# type: install
# root: true
# order: 24
# check_command: "sslscan --version"
# tags: "network, ssl, security"
# ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    pkg_install sslscan
    log_success "sslscan installed!"
else
    require_root
    pkg_remove sslscan
fi
