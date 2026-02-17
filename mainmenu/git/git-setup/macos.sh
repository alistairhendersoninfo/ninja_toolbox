#!/bin/bash
# macOS implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Git & GitHub Setup (macOS)"
    log_info "Log file: $LOG_FILE"
    echo ""

    # Step 1: Install git (macOS-specific)
    log_step "1. Installing git..."
    if command -v git &>/dev/null; then
        log_success "Git already installed: $(git --version)"
    else
        # macOS: git comes with Xcode CLI tools, or install via brew
        if command -v brew &>/dev/null; then
            brew install git
        else
            xcode-select --install 2>/dev/null || true
        fi
        log_success "Git installed: $(git --version)"
    fi
    echo ""

    # Step 2: Install GitHub CLI (macOS-specific)
    log_step "2. Installing GitHub CLI (gh)..."
    if command -v gh &>/dev/null; then
        log_success "GitHub CLI already installed: $(gh --version | head -1)"
    else
        log_info "Installing GitHub CLI..."
        brew install gh
        log_success "GitHub CLI installed: $(gh --version | head -1)"
    fi
    echo ""

    # Steps 3-7: Common across all platforms
    configure_git_user
    create_ssh_key
    authenticate_github
    upload_ssh_key
    test_github_connection

    mark_installed true
    show_summary
}

ACTION="${1:-install}"
case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
