#!/bin/bash
# Wrapper — delegates to network/web-servers/nginx.sh
MENU_ROOT="${MENU_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
exec "$MENU_ROOT/mainmenu/network/web-servers/nginx.sh" "${1:-install}"
