#!/bin/bash
# ---
# name: "Google Antigravity IDE"
# description: "Google's AI-powered agentic development platform"
# version: "1.0.0"
# author: "Google"
# root: true
# order: 20
# hidden: false
# installed: false
# check_command: "antigravity --version"
# check_path: "/usr/bin/antigravity"
# dependencies:
#   - curl
#   - gpg
# tags:
#   - ide
#   - editor
#   - ai
#   - google
#   - antigravity
# ---

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing Google Antigravity IDE..."
    log_info "Log file: $LOG_FILE"
    require_root

    # Check if already installed
    if command -v antigravity &>/dev/null; then
        log_info "Antigravity already installed"
        mark_installed true
        return 0
    fi

    case "$NT_OS" in
        linux)
            log_step "Adding Google Antigravity repository..."

            # Import GPG key
            curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor -o /usr/share/keyrings/google-antigravity.gpg

            # Add repository (DEB822 format)
            cat > /etc/apt/sources.list.d/google-antigravity.sources << 'EOF'
Types: deb
URIs: https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/
Suites: antigravity-debian
Components: main
Signed-By: /usr/share/keyrings/google-antigravity.gpg
EOF

            log_step "Updating package list..."
            apt-get update -qq

            log_step "Installing antigravity..."
            apt-get install -y antigravity
            ;;
        macos)
            log_step "Installing Antigravity via Homebrew..."
            brew install --cask antigravity
            ;;
    esac

    if command -v antigravity &>/dev/null; then
        log_success "Google Antigravity IDE installed successfully!"
        echo ""
        echo "Run 'antigravity' to launch"
        echo "Or 'antigravity /path/to/project' to open a project"
        echo ""
        mark_installed true
    else
        log_error "Antigravity installation failed"
        exit 1
    fi
}

uninstall() {
    log_info "Removing Google Antigravity IDE..."
    require_root

    case "$NT_OS" in
        linux)
            apt-get remove -y antigravity || true
            rm -f /etc/apt/sources.list.d/google-antigravity.sources
            rm -f /usr/share/keyrings/google-antigravity.gpg
            apt-get update -qq
            ;;
        macos)
            brew uninstall --cask antigravity 2>/dev/null || true
            ;;
    esac

    rm -rf ~/.config/antigravity
    rm -rf ~/.antigravity

    log_success "Google Antigravity IDE removed"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
