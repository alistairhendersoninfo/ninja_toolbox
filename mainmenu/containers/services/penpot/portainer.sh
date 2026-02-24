#!/bin/bash
# Wrapper — delegates to containers/runtime/portainer.sh
MENU_ROOT="${MENU_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
exec "$MENU_ROOT/mainmenu/containers/runtime/portainer.sh" "${1:-install}"
