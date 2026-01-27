#!/bin/bash
# ---
# name: "Git & GitHub Setup"
# description: "Install git, create SSH key, configure GitHub authentication, init repo"
# version: "1.0.0"
# author: "System"
# root: false
# order: 5
# hidden: false
# installed: false
# check_command: "git --version"
# check_path: "~/.ssh/id_ed25519"
# dependencies: []
# tags:
#   - git
#   - github
#   - ssh
#   - dev
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
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

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
    log_info "Git & GitHub Setup"
    log_info "Log file: $LOG_FILE"
    echo ""

    # Step 1: Install git
    log_step "1. Installing git..."
    if command -v git &>/dev/null; then
        log_success "Git already installed: $(git --version)"
    else
        sudo apt-get update
        sudo apt-get install -y git
        log_success "Git installed: $(git --version)"
    fi
    echo ""

    # Step 2: Configure git user
    log_step "2. Configuring git user..."

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

    log_success "Git configured as: $(git config --global user.name) <$(git config --global user.email)>"
    echo ""

    # Step 3: Create SSH key
    log_step "3. Creating SSH key for GitHub..."

    SSH_KEY="$HOME/.ssh/id_ed25519"
    SSH_KEY_PUB="$HOME/.ssh/id_ed25519.pub"

    if [[ -f "$SSH_KEY" ]]; then
        log_warn "SSH key already exists at $SSH_KEY"
        read -p "Create a new key? (y/N): " create_new
        if [[ "$create_new" != "y" && "$create_new" != "Y" ]]; then
            log_info "Using existing SSH key"
        else
            # Backup old key
            mv "$SSH_KEY" "$SSH_KEY.backup.$(date +%Y%m%d_%H%M%S)"
            mv "$SSH_KEY_PUB" "$SSH_KEY_PUB.backup.$(date +%Y%m%d_%H%M%S)"
            ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$SSH_KEY" -N ""
            log_success "New SSH key created"
        fi
    else
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$SSH_KEY" -N ""
        log_success "SSH key created at $SSH_KEY"
    fi
    echo ""

    # Step 4: Start SSH agent and add key
    log_step "4. Adding key to SSH agent..."
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY"
    log_success "Key added to SSH agent"
    echo ""

    # Step 5: Display the public key and instructions
    log_step "5. Add this SSH key to GitHub"
    echo ""
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}  ${BOLD}Your SSH Public Key (copy everything below):${NC}                               ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo ""
    cat "$SSH_KEY_PUB"
    echo ""
    echo -e "${MAGENTA}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${MAGENTA}║${NC}  ${BOLD}How to add this key to GitHub:${NC}                                              ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                                                                              ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  1. Go to: ${CYAN}https://github.com/settings/keys${NC}                                 ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  2. Click ${GREEN}\"New SSH key\"${NC}                                                     ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  3. Title: ${YELLOW}$(hostname) - $(date +%Y-%m-%d)${NC}                                  ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  4. Key type: ${YELLOW}Authentication Key${NC}                                            ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  5. Paste the key above into the \"Key\" field                                 ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  6. Click ${GREEN}\"Add SSH key\"${NC}                                                     ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Copy to clipboard if xclip is available
    if command -v xclip &>/dev/null; then
        cat "$SSH_KEY_PUB" | xclip -selection clipboard
        log_success "Key copied to clipboard!"
    elif command -v xsel &>/dev/null; then
        cat "$SSH_KEY_PUB" | xsel --clipboard
        log_success "Key copied to clipboard!"
    else
        log_info "Install xclip to auto-copy: sudo apt install xclip"
    fi
    echo ""

    # Step 6: Wait for user to add key, then test
    read -p "Press Enter after you've added the key to GitHub..."
    echo ""

    log_step "6. Testing GitHub SSH authentication..."
    echo ""
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log_success "GitHub SSH authentication successful!"
    else
        # GitHub returns exit code 1 even on success, check the message
        result=$(ssh -T git@github.com 2>&1 || true)
        if echo "$result" | grep -q "Hi.*You've successfully authenticated"; then
            log_success "GitHub SSH authentication successful!"
            echo -e "${GREEN}$result${NC}"
        else
            log_warn "Authentication test result:"
            echo "$result"
            log_info "If you see 'Permission denied', make sure you added the key to GitHub"
        fi
    fi
    echo ""

    # Step 7: Initialize git repo in menu-installer if not already
    log_step "7. Initializing git repository..."

    cd "$MENU_ROOT"

    if [[ -d ".git" ]]; then
        log_info "Git repository already initialized"
    else
        git init
        log_success "Git repository initialized"
    fi
    echo ""

    # Step 8: Create .gitignore
    log_step "8. Creating .gitignore..."

    cat > "$MENU_ROOT/.gitignore" << 'EOF'
# Logs
.docs/logs/
*.log

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
.venv/
venv/
ENV/
env/

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Secrets
.env
*.pem
*.key
credentials.json

# Temp files
*.tmp
*.temp
.cache/
EOF

    log_success "Created .gitignore"
    echo ""

    # Step 9: Initial commit
    log_step "9. Creating initial commit..."

    git add -A

    # Check if there are changes to commit
    if git diff --cached --quiet; then
        log_info "No changes to commit"
    else
        git commit -m "Initial commit - NinjaMenu installer system

- Menu-driven installer with Textual/whiptail backends
- Dynamic script discovery from folder structure
- YAML header parsing for script metadata
- Installation status detection
- Logging system

Co-Authored-By: Claude <noreply@anthropic.com>"
        log_success "Initial commit created"
    fi
    echo ""

    # Step 10: Setup remote and push
    log_step "10. Setting up GitHub remote..."

    current_remote=$(git remote get-url origin 2>/dev/null || echo "")

    if [[ -n "$current_remote" ]]; then
        log_info "Remote already set: $current_remote"
        read -p "Change remote? (y/N): " change_remote
        if [[ "$change_remote" == "y" || "$change_remote" == "Y" ]]; then
            read -p "Enter GitHub repo URL (git@github.com:user/repo.git): " repo_url
            git remote set-url origin "$repo_url"
        fi
    else
        read -p "Enter GitHub repo URL (git@github.com:user/repo.git): " repo_url
        if [[ -n "$repo_url" ]]; then
            git remote add origin "$repo_url"
            log_success "Remote added: $repo_url"
        else
            log_warn "No remote URL provided - skipping push"
            mark_installed true
            echo ""
            log_success "Git setup complete! Add remote later with:"
            echo "  git remote add origin git@github.com:username/repo.git"
            echo "  git push -u origin main"
            return
        fi
    fi
    echo ""

    # Push to remote
    log_step "11. Pushing to GitHub..."

    # Ensure we're on main branch
    current_branch=$(git branch --show-current)
    if [[ "$current_branch" != "main" ]]; then
        git branch -M main
    fi

    if git push -u origin main; then
        log_success "Pushed to GitHub successfully!"
    else
        log_warn "Push failed - you may need to create the repo on GitHub first"
        log_info "Create repo at: https://github.com/new"
        log_info "Then run: git push -u origin main"
    fi
    echo ""

    mark_installed true

    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}Git & GitHub Setup Complete!${NC}                                                ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}  Git user: $(git config --global user.name) <$(git config --global user.email)>"
    echo -e "${GREEN}║${NC}  SSH key:  $SSH_KEY_PUB"
    echo -e "${GREEN}║${NC}  Repo:     $MENU_ROOT"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

uninstall() {
    log_info "This will remove git configuration and SSH keys"
    log_warn "This is a destructive operation!"
    echo ""
    read -p "Are you sure? (type 'yes' to confirm): " confirm

    if [[ "$confirm" != "yes" ]]; then
        log_info "Uninstall cancelled"
        return
    fi

    # Remove SSH key
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        rm -f "$HOME/.ssh/id_ed25519"
        rm -f "$HOME/.ssh/id_ed25519.pub"
        log_success "Removed SSH key"
    fi

    # Remove git config
    git config --global --unset user.name 2>/dev/null || true
    git config --global --unset user.email 2>/dev/null || true
    log_success "Removed git global config"

    mark_installed false
    log_success "Git setup removed"
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
