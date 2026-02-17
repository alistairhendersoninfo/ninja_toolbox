#!/bin/bash
# Shared functions for git-setup — sourced by all OS scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
SCRIPT_NAME="git-setup"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOG_DIR"

MAGENTA='\033[0;35m'
BOLD='\033[1m'

# Step 3: Configure git user
configure_git_user() {
    log_step "3. Configuring git user..."

    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")

    if [[ -n "$current_name" ]]; then
        log_info "Current git name: $current_name"
        read -p "Keep this name? (Y/n): " keep_name
        if [[ "$keep_name" == "n" || "$keep_name" == "N" ]]; then
            read -p "Enter your name: " git_name
            git config --global user.name "$git_name"
        fi
    else
        read -p "Enter your name for git commits: " git_name
        git config --global user.name "$git_name"
    fi

    if [[ -n "$current_email" ]]; then
        log_info "Current git email: $current_email"
        read -p "Keep this email? (Y/n): " keep_email
        if [[ "$keep_email" == "n" || "$keep_email" == "N" ]]; then
            read -p "Enter your email: " git_email
            git config --global user.email "$git_email"
        fi
    else
        read -p "Enter your email for git commits: " git_email
        git config --global user.email "$git_email"
    fi

    # Set default branch to main
    git config --global init.defaultBranch main

    log_success "Git configured as: $(git config --global user.name) <$(git config --global user.email)>"
    echo ""
}

# Step 4: Create SSH key
create_ssh_key() {
    log_step "4. Creating SSH key for GitHub..."

    SSH_KEY="$HOME/.ssh/id_ed25519"
    SSH_KEY_PUB="$HOME/.ssh/id_ed25519.pub"

    if [[ -f "$SSH_KEY" ]]; then
        log_warn "SSH key already exists at $SSH_KEY"
        read -p "Create a new key? (y/N): " create_new
        if [[ "$create_new" == "y" || "$create_new" == "Y" ]]; then
            mv "$SSH_KEY" "$SSH_KEY.backup.$(date +%Y%m%d_%H%M%S)"
            mv "$SSH_KEY_PUB" "$SSH_KEY_PUB.backup.$(date +%Y%m%d_%H%M%S)"
            ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$SSH_KEY" -N ""
            log_success "New SSH key created"
        else
            log_info "Using existing SSH key"
        fi
    else
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$SSH_KEY" -N ""
        log_success "SSH key created at $SSH_KEY"
    fi

    # Start SSH agent and add key
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add "$SSH_KEY" 2>/dev/null
    log_success "Key added to SSH agent"
    echo ""
}

# Step 5: Authenticate with GitHub CLI
authenticate_github() {
    log_step "5. Authenticating with GitHub..."

    if gh auth status &>/dev/null; then
        log_success "Already authenticated with GitHub"
        gh auth status
    else
        echo ""
        echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}║${NC}  ${BOLD}GitHub CLI Authentication${NC}                                                   ${MAGENTA}║${NC}"
        echo -e "${MAGENTA}║${NC}                                                                              ${MAGENTA}║${NC}"
        echo -e "${MAGENTA}║${NC}  When prompted:                                                              ${MAGENTA}║${NC}"
        echo -e "${MAGENTA}║${NC}    - Account: ${CYAN}GitHub.com${NC}                                                     ${MAGENTA}║${NC}"
        echo -e "${MAGENTA}║${NC}    - Protocol: ${CYAN}SSH${NC}                                                           ${MAGENTA}║${NC}"
        echo -e "${MAGENTA}║${NC}    - Upload SSH key: ${CYAN}Yes${NC}                                                     ${MAGENTA}║${NC}"
        echo -e "${MAGENTA}║${NC}    - Auth method: ${CYAN}Login with a web browser${NC}                                   ${MAGENTA}║${NC}"
        echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""

        gh auth login
        log_success "GitHub authentication complete"
    fi
    echo ""
}

# Step 6: Ensure SSH key is on GitHub
upload_ssh_key() {
    log_step "6. Checking SSH key on GitHub..."

    SSH_KEY_PUB="$HOME/.ssh/id_ed25519.pub"
    KEY_TITLE="$(hostname)-$(date +%Y%m%d)"
    KEY_FINGERPRINT=$(ssh-keygen -lf "$SSH_KEY_PUB" | awk '{print $2}')

    # Check if key already exists on GitHub
    if gh ssh-key list 2>/dev/null | grep -q "$KEY_FINGERPRINT"; then
        log_info "SSH key already on GitHub"
    else
        gh ssh-key add "$SSH_KEY_PUB" --title "$KEY_TITLE" --type authentication
        log_success "SSH key uploaded to GitHub as: $KEY_TITLE"
    fi
    echo ""
}

# Step 7: Test SSH connection
test_github_connection() {
    log_step "7. Testing GitHub SSH connection..."

    result=$(ssh -T git@github.com 2>&1 || true)
    if echo "$result" | grep -qi "successfully authenticated"; then
        log_success "GitHub SSH authentication working!"
        echo -e "${GREEN}$result${NC}"
    else
        log_warn "SSH test output: $result"
    fi
    echo ""
}

# Final summary
show_summary() {
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}Git & GitHub Setup Complete!${NC}                                                ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}  Git User:   $(git config --global user.name) <$(git config --global user.email)>"
    echo -e "${GREEN}║${NC}  SSH Key:    ~/.ssh/id_ed25519"
    echo -e "${GREEN}║${NC}  GitHub:     Authenticated as $(gh api user -q .login)"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}  Next steps:                                                                 ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}    - ${CYAN}Test GitHub Connection${NC} - Verify SSH works                               ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}    - ${CYAN}Push to GitHub Repo${NC} - Push a folder to GitHub                           ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Uninstall function
uninstall() {
    log_info "To reset credentials, use 'Reset Git Credentials' from the menu"
    log_info "This preserves your repository but allows re-authentication"
    mark_installed false
}
