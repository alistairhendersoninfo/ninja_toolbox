# Git & GitHub - Technical Manual

## Architecture

The Git menu provides credential management and repository operations using SSH-based authentication. All scripts use the GitHub CLI (`gh`) for API operations and native SSH for Git operations.

## Scripts Reference

### git-setup.sh

**Purpose:** Initial Git and GitHub setup with SSH authentication

**Location:** `mainmenu/git/git-setup.sh`

**YAML Header:**
```yaml
name: "Git & GitHub Setup"
type: install
root: false
order: 10
check_command: "gh auth status"
check_path: "~/.ssh/id_ed25519"
```

**Functions:**
- `install()` - Installs git, gh CLI, creates SSH key, authenticates with GitHub
- `uninstall()` - Marks as uninstalled (credentials preserved)

**Process Flow:**
1. Install git (apt)
2. Install GitHub CLI (gh) from official repo
3. Configure git user.name and user.email
4. Generate ED25519 SSH key
5. Start ssh-agent and add key
6. Authenticate with `gh auth login` (browser flow)
7. Upload SSH key to GitHub via `gh ssh-key add`
8. Test SSH connection

**Dependencies:**
- curl (for gh installation)

### test-connection.sh

**Purpose:** Verify GitHub SSH connectivity

**Location:** `mainmenu/git/test-connection.sh`

**YAML Header:**
```yaml
name: "Test GitHub Connection"
type: config
root: false
order: 15
```

**Checks performed:**
1. SSH key file exists (`~/.ssh/id_ed25519` or `~/.ssh/id_rsa`)
2. SSH agent running with keys loaded (`ssh-add -l`)
3. GitHub CLI authenticated (`gh auth status`)
4. Git global config set (`git config --global user.name/email`)
5. SSH connection to GitHub (`ssh -T git@github.com`)

### reset-credentials.sh

**Purpose:** Clear authentication state

**Location:** `mainmenu/git/reset-credentials.sh`

**YAML Header:**
```yaml
name: "Reset Git Credentials"
type: config
root: false
order: 20
```

**Actions (reset):**
- `gh auth logout`
- `git config --global --unset user.name/email`
- `git credential-cache exit`
- Remove `~/.git-credentials`
- Kill ssh-agent processes

**Actions (destroy):**
- All of the above
- Remove `~/.ssh/id_ed25519` and `~/.ssh/id_ed25519.pub`

### push-to-repo.sh

**Purpose:** Create GitHub repository and push local folder

**Location:** `mainmenu/git/push-to-repo.sh`

**YAML Header:**
```yaml
name: "Push to GitHub Repo"
type: config
root: false
order: 25
```

**Process Flow:**
1. Verify `gh` installed and authenticated
2. Get folder path from user
3. Get repo name (default: folder basename)
4. Get visibility (private/public)
5. Get description (optional)
6. Check if repo exists on GitHub
7. Initialize git if needed
8. Create .gitignore if missing
9. Create README.md if missing
10. Create GitHub repo with `gh repo create`
11. Stage, commit, push

**Repository Creation:**
```bash
gh repo create "$repo_name" --"$visibility" --source . --remote origin --push
```

## Integration Points

### External Services
- **GitHub API**: Via `gh` CLI for repo creation, SSH key management
- **GitHub SSH**: `git@github.com` for push/pull operations

### File Locations
- SSH Keys: `~/.ssh/id_ed25519`, `~/.ssh/id_ed25519.pub`
- Git Config: `~/.gitconfig`
- Credentials: `~/.git-credentials` (if using credential helper)
- Logs: `.docs/logs/git-setup_*.log`, etc.

## Security Considerations

- SSH keys created with no passphrase for automation (user can add passphrase manually)
- GitHub CLI uses OAuth token stored in `~/.config/gh/hosts.yml`
- Credential cache cleared on reset
- SSH agent processes killed on reset

## Development

### Adding a New Git Script

1. Copy template: `cp .docs/templates/config_template.sh mainmenu/git/new-script.sh`
2. Set appropriate order number
3. Implement functionality
4. Update this documentation

### Testing

```bash
# Test setup
bash mainmenu/git/git-setup.sh install

# Test connection
bash mainmenu/git/test-connection.sh install

# Test push (create test folder first)
mkdir /tmp/test-repo
bash mainmenu/git/push-to-repo.sh install
```

## Changelog

- **v2.0.0** - Separated setup from push, added test connection
- **v1.0.0** - Initial implementation

## See Also

- [User Guide](../user_manuals/git.md)
