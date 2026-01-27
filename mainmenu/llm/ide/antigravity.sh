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

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()    { echo -e "${CYAN}[STEP]${NC} $1"; }

mark_installed() {
    local status="${1:-true}"
    sed -i "s/^# installed: .*/# installed: $status/" "${BASH_SOURCE[0]}"
}

install() {
    log_info "Installing Google Antigravity IDE..."
    log_info "Log file: $LOG_FILE"

    # Check if already installed
    if command -v antigravity &>/dev/null; then
        log_info "Antigravity already installed: $(dpkg-query -W -f='${Version}' antigravity 2>/dev/null || echo 'version unknown')"
        mark_installed true
        return 0
    fi

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

    apt-get remove -y antigravity || true

    # Remove repository
    rm -f /etc/apt/sources.list.d/google-antigravity.sources
    rm -f /usr/share/keyrings/google-antigravity.gpg

    apt-get update -qq

    # Remove config
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
