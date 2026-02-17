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

MAGENTA='\033[0;35m'
BOLD='\033[1m'

install() {
    echo ""
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}  ${BOLD}Push to GitHub Repository${NC}                                                   ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Check prerequisites
    if ! command -v gh &>/dev/null; then
        log_error "GitHub CLI (gh) not installed"
        log_info "Run 'Git & GitHub Setup' first"
        return 1
    fi

    if ! gh auth status &>/dev/null; then
        log_error "Not authenticated with GitHub"
        log_info "Run 'Git & GitHub Setup' first"
        return 1
    fi

    GITHUB_USER=$(gh api user -q .login)
    log_success "Authenticated as: $GITHUB_USER"
    echo ""

    # Step 1: Get the folder path
    log_step "1. Select folder to push"
    echo ""
    echo "Enter the path to the folder you want to push to GitHub."
    echo "Use '.' for current directory, or an absolute/relative path."
    echo ""
    read -p "Folder path [.]: " folder_path
    folder_path="${folder_path:-.}"

    # Expand and validate path
    folder_path=$(realpath "$folder_path" 2>/dev/null || echo "$folder_path")

    if [[ ! -d "$folder_path" ]]; then
        log_error "Directory not found: $folder_path"
        return 1
    fi

    log_success "Selected: $folder_path"
    echo ""

    # Step 2: Get repo name
    log_step "2. Repository name"
    default_name=$(basename "$folder_path")
    read -p "Repository name [$default_name]: " repo_name
    repo_name="${repo_name:-$default_name}"

    # Sanitize repo name (replace spaces with hyphens, remove special chars)
    repo_name=$(echo "$repo_name" | tr ' ' '-' | tr -cd '[:alnum:]-_.')

    log_info "Repository will be: $GITHUB_USER/$repo_name"
    echo ""

    # Step 3: Get visibility
    log_step "3. Repository visibility"
    echo ""
    echo "  1) Private - Only you can see this repository"
    echo "  2) Public  - Anyone can see this repository"
    read -p "Choose [1]: " visibility_choice
    visibility_choice="${visibility_choice:-1}"

    if [[ "$visibility_choice" == "2" ]]; then
        visibility="public"
    else
        visibility="private"
    fi
    log_info "Visibility: $visibility"
    echo ""

    # Step 4: Get description
    log_step "4. Repository description"
    read -p "Description (optional): " repo_description
    echo ""

    # Step 5: Check if repo already exists
    log_step "5. Checking if repository exists..."
    if gh repo view "$GITHUB_USER/$repo_name" &>/dev/null; then
        log_warn "Repository '$repo_name' already exists on GitHub"
        echo ""
        echo "Options:"
        echo "  1) Push to existing repo (may overwrite)"
        echo "  2) Choose a different name"
        echo "  3) Cancel"
        read -p "Choose [3]: " existing_choice
        existing_choice="${existing_choice:-3}"

        case "$existing_choice" in
            1)
                log_info "Will push to existing repo"
                create_repo=false
                ;;
            2)
                read -p "Enter new repository name: " repo_name
                repo_name=$(echo "$repo_name" | tr ' ' '-' | tr -cd '[:alnum:]-_.')
                create_repo=true
                ;;
            *)
                log_info "Cancelled"
                return 0
                ;;
        esac
    else
        create_repo=true
    fi
    echo ""

    # Change to the folder
    cd "$folder_path"

    # Step 6: Initialize git if needed
    log_step "6. Initializing git repository..."
    if [[ -d ".git" ]]; then
        log_info "Git already initialized"
    else
        git init
        log_success "Git initialized"
    fi
    echo ""

    # Step 7: Create .gitignore if it doesn't exist
    if [[ ! -f ".gitignore" ]]; then
        log_step "7. Creating .gitignore..."
        cat > ".gitignore" << 'EOF'
# Logs
*.log

# Python
__pycache__/
*.py[cod]
.venv/
venv/

# IDE
.idea/
.vscode/
*.swp
*~

# OS
.DS_Store
Thumbs.db

# Secrets
.env
*.pem
*.key
EOF
        log_success "Created .gitignore"
    else
        log_step "7. .gitignore already exists"
    fi
    echo ""

    # Step 8: Create README if it doesn't exist
    if [[ ! -f "README.md" ]]; then
        log_step "8. Creating README.md..."
        cat > "README.md" << EOF
# $repo_name

${repo_description:-A project repository.}
EOF
        log_success "Created README.md"
    else
        log_step "8. README.md already exists"
    fi
    echo ""

    # Step 9: Create repo on GitHub if needed
    if [[ "$create_repo" == "true" ]]; then
        log_step "9. Creating GitHub repository..."
        if [[ -n "$repo_description" ]]; then
            gh repo create "$repo_name" --"$visibility" --description "$repo_description" --source . --remote origin
        else
            gh repo create "$repo_name" --"$visibility" --source . --remote origin
        fi
        log_success "Repository created: https://github.com/$GITHUB_USER/$repo_name"
    else
        log_step "9. Connecting to existing repository..."
        git remote remove origin 2>/dev/null || true
        git remote add origin "git@github.com:$GITHUB_USER/$repo_name.git"
        log_success "Remote set to: git@github.com:$GITHUB_USER/$repo_name.git"
    fi
    echo ""

    # Step 10: Stage and commit
    log_step "10. Staging and committing files..."
    git add -A

    if git diff --cached --quiet; then
        log_info "No new changes to commit"
    else
        # Get commit message
        read -p "Commit message [Initial commit]: " commit_msg
        commit_msg="${commit_msg:-Initial commit}"

        git commit -m "$commit_msg

Co-Authored-By: Claude <noreply@anthropic.com>"
        log_success "Committed: $commit_msg"
    fi
    echo ""

    # Step 11: Push
    log_step "11. Pushing to GitHub..."
    git branch -M main

    if git push -u origin main; then
        log_success "Pushed successfully!"
    else
        log_warn "Push failed, trying force push..."
        read -p "Force push? This will overwrite remote. (y/N): " force_confirm
        if [[ "$force_confirm" == "y" || "$force_confirm" == "Y" ]]; then
            git push -u origin main --force
            log_success "Force pushed successfully!"
        else
            log_error "Push cancelled"
            return 1
        fi
    fi
    echo ""

    # Final summary
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}Push Complete!${NC}                                                                ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}  Repository: ${CYAN}https://github.com/$GITHUB_USER/$repo_name${NC}"
    echo -e "${GREEN}║${NC}  Visibility: ${YELLOW}$visibility${NC}"
    echo -e "${GREEN}║${NC}  Local path: $folder_path"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

uninstall() {
    log_info "Nothing to uninstall - this is a utility"
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
