#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

BOLD='\033[1m'

install() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${BOLD}GitHub Connection Test${NC}                                                       ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Check 1: SSH key exists
    log_step "1. Checking SSH key..."
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        log_success "SSH key found: ~/.ssh/id_ed25519"
        echo "    Fingerprint: $(ssh-keygen -lf "$HOME/.ssh/id_ed25519.pub" 2>/dev/null | awk '{print $2}')"
    elif [[ -f "$HOME/.ssh/id_rsa" ]]; then
        log_success "SSH key found: ~/.ssh/id_rsa"
        echo "    Fingerprint: $(ssh-keygen -lf "$HOME/.ssh/id_rsa.pub" 2>/dev/null | awk '{print $2}')"
    else
        log_error "No SSH key found"
        log_info "Run 'Git & GitHub Setup' to create one"
        return 1
    fi
    echo ""

    # Check 2: SSH agent
    log_step "2. Checking SSH agent..."
    if ssh-add -l &>/dev/null; then
        log_success "SSH agent running with keys loaded"
    else
        log_warn "SSH agent not running or no keys loaded"
        log_info "Starting SSH agent and adding key..."
        eval "$(ssh-agent -s)" >/dev/null
        ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || ssh-add "$HOME/.ssh/id_rsa" 2>/dev/null || true
    fi
    echo ""

    # Check 3: GitHub CLI auth
    log_step "3. Checking GitHub CLI authentication..."
    if command -v gh &>/dev/null; then
        if gh auth status &>/dev/null; then
            GITHUB_USER=$(gh api user -q .login 2>/dev/null || echo "unknown")
            log_success "GitHub CLI authenticated as: $GITHUB_USER"
        else
            log_warn "GitHub CLI not authenticated"
            log_info "Run 'Git & GitHub Setup' to authenticate"
        fi
    else
        log_warn "GitHub CLI (gh) not installed"
    fi
    echo ""

    # Check 4: Git config
    log_step "4. Checking git configuration..."
    GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
    GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
    if [[ -n "$GIT_NAME" && -n "$GIT_EMAIL" ]]; then
        log_success "Git configured: $GIT_NAME <$GIT_EMAIL>"
    else
        log_warn "Git user not configured"
        log_info "Run 'Git & GitHub Setup' to configure"
    fi
    echo ""

    # Check 5: SSH connection to GitHub
    log_step "5. Testing SSH connection to GitHub..."
    echo ""
    result=$(ssh -T git@github.com 2>&1 || true)

    if echo "$result" | grep -qi "successfully authenticated"; then
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║${NC}  ${BOLD}CONNECTION SUCCESSFUL${NC}                                                        ${GREEN}║${NC}"
        echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║${NC}  $result"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    elif echo "$result" | grep -qi "permission denied"; then
        echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${NC}  ${BOLD}CONNECTION FAILED${NC}                                                             ${RED}║${NC}"
        echo -e "${RED}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${RED}║${NC}  Permission denied - SSH key not recognized by GitHub                        ${RED}║${NC}"
        echo -e "${RED}║${NC}                                                                              ${RED}║${NC}"
        echo -e "${RED}║${NC}  Your public key:                                                            ${RED}║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        cat "$HOME/.ssh/id_ed25519.pub" 2>/dev/null || cat "$HOME/.ssh/id_rsa.pub" 2>/dev/null || echo "No key found"
        echo ""
        log_info "Add this key at: https://github.com/settings/keys"
    else
        log_warn "Unexpected response:"
        echo "$result"
    fi
    echo ""
}

uninstall() {
    log_info "Nothing to uninstall - this is a test utility"
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
