#!/bin/bash
# ---
# name: "Gemini CLI"
# description: "Google's Gemini AI command-line interface"
# version: "1.0.0"
# author: "Google"
# root: true
# order: 20
# hidden: false
# installed: false
# check_command: "gemini --version"
# check_path: ""
# dependencies:
#   - npm
#   - nodejs
# tags:
#   - llm
#   - cli
#   - google
#   - ai
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

check_nodejs() {
    if ! command -v node &>/dev/null; then
        log_error "Node.js is not installed. Please install Node.js first."
        log_info "Run the Node.js installer from postsetup-kali menu"
        exit 1
    fi
    if ! command -v npm &>/dev/null; then
        log_error "npm is not installed. Please install npm first."
        exit 1
    fi
}

install() {
    log_info "Installing Gemini CLI..."
    log_info "Log file: $LOG_FILE"

    check_nodejs

    # Check if already installed
    if command -v gemini &>/dev/null; then
        log_info "Gemini CLI already installed"
        mark_installed true
        return 0
    fi

    log_step "Installing @google/gemini-cli via npm..."
    npm install -g @google/gemini-cli

    if command -v gemini &>/dev/null; then
        log_success "Gemini CLI installed successfully!"
        echo ""
        echo "Run 'gemini' to start using it"
        echo ""
        mark_installed true
    else
        log_error "Gemini CLI installation failed"
        exit 1
    fi
}

uninstall() {
    log_info "Removing Gemini CLI..."

    npm uninstall -g @google/gemini-cli || true

    log_success "Gemini CLI removed"

    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
