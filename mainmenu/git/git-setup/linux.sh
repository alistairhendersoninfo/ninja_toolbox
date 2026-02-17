#!/bin/bash
# Linux implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Git & GitHub Setup (Linux)"
    log_info "Log file: $LOG_FILE"
    echo ""

    # Step 1: Install git (Linux-specific)
    log_step "1. Installing git..."
    if command -v git &>/dev/null; then
        log_success "Git already installed: $(git --version)"
    else
        sudo apt-get update
        sudo apt-get install -y git
        log_success "Git installed: $(git --version)"
    fi
    echo ""

    # Step 2: Install GitHub CLI (Linux-specific)
    log_step "2. Installing GitHub CLI (gh)..."
    if command -v gh &>/dev/null; then
        log_success "GitHub CLI already installed: $(gh --version | head -1)"
    else
        log_info "Installing GitHub CLI..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y gh
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
