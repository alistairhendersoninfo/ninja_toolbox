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
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC}  ${BOLD}Reset Git & GitHub Credentials${NC}                                              ${YELLOW}║${NC}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║${NC}                                                                              ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  This will reset:                                                            ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}    - Logout from GitHub CLI                                                  ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}    - Clear git global user config (name/email)                               ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}    - Clear cached credentials                                                ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}                                                                              ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${GREEN}SSH keys will be preserved unless you type 'destroy'${NC}                       ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    read -p "Type 'reset' to reset (keep SSH keys) or 'destroy' to also remove SSH keys: " confirm

    if [[ "$confirm" != "reset" && "$confirm" != "destroy" ]]; then
        log_info "Cancelled - no changes made"
        return
    fi

    echo ""
    log_warn "Resetting Git & GitHub credentials..."
    echo ""

    # Step 1: Logout from GitHub CLI
    log_step "1. Logging out from GitHub CLI..."
    if command -v gh &>/dev/null; then
        if gh auth status &>/dev/null; then
            gh auth logout --hostname github.com 2>/dev/null || true
            log_success "Logged out from GitHub"
        else
            log_info "Not logged into GitHub CLI"
        fi
    else
        log_info "GitHub CLI not installed"
    fi

    # Step 2: Clear git config
    log_step "2. Clearing git global config..."
    git config --global --unset user.name 2>/dev/null || true
    git config --global --unset user.email 2>/dev/null || true
    log_success "Git user config cleared"

    # Step 3: Remove credential helpers/cache
    log_step "3. Clearing credential cache..."
    git credential-cache exit 2>/dev/null || true
    rm -f "$HOME/.git-credentials" 2>/dev/null || true
    git config --global --unset credential.helper 2>/dev/null || true
    log_success "Credential cache cleared"

    # Step 4: Stop SSH agent
    log_step "4. Stopping SSH agent..."
    pkill -u "$USER" ssh-agent 2>/dev/null || true
    log_success "SSH agent stopped"

    # Step 5: Only remove SSH keys if user typed 'destroy'
    if [[ "$confirm" == "destroy" ]]; then
        log_step "5. Removing SSH keys..."
        if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
            rm -f "$HOME/.ssh/id_ed25519"
            rm -f "$HOME/.ssh/id_ed25519.pub"
            log_success "SSH keys destroyed"
        else
            log_info "No SSH keys found"
        fi
    else
        log_step "5. SSH keys preserved"
        if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
            log_info "SSH key still at: ~/.ssh/id_ed25519"
        fi
    fi

    # Mark git-setup as not installed
    GIT_SETUP="$SCRIPT_DIR/git-setup.sh"
    if [[ -f "$GIT_SETUP" ]]; then
        nt_sed_i "s/^# installed: .*/# installed: false/" "$GIT_SETUP"
    fi

    echo ""
    if [[ "$confirm" == "destroy" ]]; then
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║${NC}  ${BOLD}Full Reset Complete!${NC}                                                        ${GREEN}║${NC}"
        echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║${NC}  All credentials and SSH keys have been removed.                            ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}                                                                              ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}  To set up fresh credentials:                                               ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}    Run ${CYAN}ninjamenu${NC} -> Git -> Git & GitHub Setup                               ${GREEN}║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║${NC}  ${BOLD}Credentials Reset Complete!${NC}                                                  ${GREEN}║${NC}"
        echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║${NC}  Git & GitHub credentials cleared. ${CYAN}SSH keys preserved.${NC}                       ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}                                                                              ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}  To re-authenticate with your existing SSH key:                             ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}    Run ${CYAN}ninjamenu${NC} -> Git -> Git & GitHub Setup                               ${GREEN}║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    fi
    echo ""
}

uninstall() {
    log_info "Nothing to uninstall - this is a reset utility"
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
