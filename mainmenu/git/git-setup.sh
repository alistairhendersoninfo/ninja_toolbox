#!/bin/bash
# ---
# name: "Git & GitHub Setup"
# description: "Install git/gh, create SSH key, create GitHub repo, initial push"
# version: "2.0.0"
# author: "System"
# root: false
# order: 10
# hidden: false
# installed: false
# check_command: "gh auth status"
# check_path: "~/.ssh/id_ed25519"
# dependencies:
#   - curl
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

    # Step 2: Install GitHub CLI
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

    # Step 3: Configure git user
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

    # Step 4: Create SSH key
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

    # Step 5: Authenticate with GitHub CLI
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

    # Step 6: Ensure SSH key is on GitHub
    log_step "6. Checking SSH key on GitHub..."

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

    # Step 7: Test SSH connection
    log_step "7. Testing GitHub SSH connection..."

    result=$(ssh -T git@github.com 2>&1 || true)
    if echo "$result" | grep -qi "successfully authenticated"; then
        log_success "GitHub SSH authentication working!"
        echo -e "${GREEN}$result${NC}"
    else
        log_warn "SSH test output: $result"
    fi
    echo ""

    mark_installed true

    # Final summary
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

uninstall() {
    log_info "To reset credentials, use 'Reset Git Credentials' from the menu"
    log_info "This preserves your repository but allows re-authentication"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
    echo ""

    # Get repo name
    default_name=$(basename "$MENU_ROOT")
    read -p "Repository name [$default_name]: " repo_name
    repo_name="${repo_name:-$default_name}"

    # Get visibility
    echo ""
    echo "Repository visibility:"
    echo "  1) Private - Only you can see this repository"
    echo "  2) Public  - Anyone can see this repository"
    read -p "Choose [1]: " visibility_choice
    visibility_choice="${visibility_choice:-1}"

    if [[ "$visibility_choice" == "2" ]]; then
        visibility="public"
    else
        visibility="private"
    fi

    # Get description
    echo ""
    read -p "Repository description: " repo_description
    repo_description="${repo_description:-NinjaMenu - Kali Linux installer system}"

    echo ""

    # Step 9: Initialize git repo
    log_step "9. Initializing local git repository..."

    cd "$MENU_ROOT"

    if [[ -d ".git" ]]; then
        log_info "Git repository already initialized"
    else
        git init
        log_success "Git repository initialized"
    fi
    echo ""

    # Step 10: Create README.md
    log_step "10. Creating README.md..."

    GITHUB_USER=$(gh api user -q .login)

    cat > "$MENU_ROOT/README.md" << EOF
# $repo_name

$repo_description

## Overview

NinjaMenu is a dynamic menu-driven installer system for Kali Linux. It automatically discovers scripts from the folder structure and provides an interactive TUI for installation.

## Features

- Dynamic menu generation from folder structure
- YAML header parsing for script metadata
- Multiple TUI backends (Textual, whiptail, gum)
- Installation status detection
- Logging system
- Pre/post install hooks

## Installation

\`\`\`bash
# Clone the repository
git clone git@github.com:$GITHUB_USER/$repo_name.git
cd $repo_name

# Install menu dependencies
sudo bash install_menu.sh

# Run the menu
ninjamenu
\`\`\`

## Usage

\`\`\`bash
ninjamenu              # Launch interactive menu
ninjamenu --list       # List all available scripts
ninjamenu --help       # Show help
\`\`\`

## Structure

\`\`\`
mainmenu/
  ├── git/             # Git & GitHub tools
  ├── llm/             # LLM CLI tools
  │   ├── cli/         # CLI tools (Claude, Gemini, etc.)
  │   └── ide/         # IDE tools (Cursor, etc.)
  ├── postsetup-kali/  # Kali post-install setup
  └── proxmox/         # Proxmox VE tools
\`\`\`

## Adding Scripts

Create a new \`.sh\` file in any mainmenu subfolder with a YAML header:

\`\`\`bash
#!/bin/bash
# ---
# name: "My Script"
# description: "What it does"
# version: "1.0.0"
# root: false
# order: 50
# tags:
#   - category
# ---

# Your script here
\`\`\`

## License

MIT
EOF

    log_success "Created README.md"
    echo ""

    # Step 11: Create .gitignore
    log_step "11. Creating .gitignore..."

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

# Secrets & Credentials
.env
.env.*
*.pem
*.key
*.crt
credentials.json
secrets.json
*_secret*
*_token*

# Temp files
*.tmp
*.temp
.cache/

# Build
dist/
build/
*.egg-info/
EOF

    log_success "Created .gitignore"
    echo ""

    # Step 12: Create GitHub repository
    log_step "12. Creating GitHub repository..."

    # Check if repo already exists
    if gh repo view "$GITHUB_USER/$repo_name" &>/dev/null; then
        log_warn "Repository '$repo_name' already exists on GitHub"
        read -p "Use existing repo? (Y/n): " use_existing
        if [[ "$use_existing" == "n" || "$use_existing" == "N" ]]; then
            read -p "Enter new repository name: " repo_name
        fi
    fi

    # Create or connect to repo
    if gh repo view "$GITHUB_USER/$repo_name" &>/dev/null; then
        log_info "Connecting to existing repository..."
        # Remove old origin if exists
        git remote remove origin 2>/dev/null || true
        git remote add origin "git@github.com:$GITHUB_USER/$repo_name.git"
    else
        log_info "Creating new $visibility repository: $repo_name"
        gh repo create "$repo_name" --"$visibility" --description "$repo_description" --source . --remote origin --push
        log_success "Repository created and pushed!"

        mark_installed true

        # Show summary and exit early since gh repo create already pushed
        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║${NC}  ${BOLD}Git & GitHub Setup Complete!${NC}                                                ${GREEN}║${NC}"
        echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║${NC}  Repository: ${CYAN}https://github.com/$GITHUB_USER/$repo_name${NC}"
        echo -e "${GREEN}║${NC}  Visibility: ${YELLOW}$visibility${NC}"
        echo -e "${GREEN}║${NC}  SSH Key:    $SSH_KEY_PUB"
        echo -e "${GREEN}║${NC}  Git User:   $(git config --global user.name) <$(git config --global user.email)>"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        return 0
    fi
    echo ""

    # Step 13: Stage, commit, and push
    log_step "13. Creating initial commit and pushing..."

    git add -A

    if git diff --cached --quiet; then
        log_info "No new changes to commit"
    else
        git commit -m "Initial commit - NinjaMenu installer system

- Menu-driven installer with Textual/whiptail backends
- Dynamic script discovery from folder structure
- YAML header parsing for script metadata
- Installation status detection
- Logging and documentation system

Co-Authored-By: Claude <noreply@anthropic.com>"
        log_success "Commit created"
    fi

    # Ensure main branch
    git branch -M main

    # Push via SSH
    git push -u origin main
    log_success "Pushed to GitHub!"
    echo ""

    mark_installed true

    # Final summary
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}Git & GitHub Setup Complete!${NC}                                                ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}  Repository: ${CYAN}https://github.com/$GITHUB_USER/$repo_name${NC}"
    echo -e "${GREEN}║${NC}  Visibility: ${YELLOW}$visibility${NC}"
    echo -e "${GREEN}║${NC}  SSH Key:    $SSH_KEY_PUB"
    echo -e "${GREEN}║${NC}  Git User:   $(git config --global user.name) <$(git config --global user.email)>"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

uninstall() {
    log_info "To reset credentials, use 'Reset Git Credentials' from the menu"
    log_info "This preserves your repository but allows re-authentication"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
