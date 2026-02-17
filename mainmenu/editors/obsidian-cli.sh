#!/bin/bash
# Metadata in obsidian-cli.meta.yaml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    require_root

    case "$NT_OS" in
        macos)
            brew tap yakitrak/yakitrak
            brew install yakitrak/yakitrak/notesmd-cli
            ;;
        linux)
            # notesmd-cli is Go-based; install from GitHub releases
            latest_url=$(curl -fsSL https://api.github.com/repos/Yakitrak/obsidian-cli/releases/latest \
                | grep "browser_download_url.*linux.*amd64" \
                | head -1 \
                | cut -d '"' -f 4)
            if [[ -z "$latest_url" ]]; then
                log_error "Could not find notesmd-cli release for Linux"
                exit 1
            fi
            curl -fsSL "$latest_url" -o /tmp/notesmd-cli.tar.gz
            tar -xzf /tmp/notesmd-cli.tar.gz -C /usr/local/bin/
            rm -f /tmp/notesmd-cli.tar.gz
            ;;
    esac

    mark_installed true
    log_success "NotesMD CLI (Obsidian CLI) installed!"
    log_info "Run 'notesmd-cli --help' to get started."
else
    require_root

    case "$NT_OS" in
        macos)
            brew uninstall yakitrak/yakitrak/notesmd-cli 2>/dev/null || true
            ;;
        linux)
            rm -f /usr/local/bin/notesmd-cli
            ;;
    esac

    mark_installed false
    log_success "NotesMD CLI uninstalled."
fi
