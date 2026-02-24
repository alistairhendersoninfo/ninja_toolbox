#!/bin/bash
# Wrapper — delegates to containers/runtime/docker.sh
MENU_ROOT="${MENU_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
exec "$MENU_ROOT/mainmenu/containers/runtime/docker.sh" "${1:-install}"
