---
layout: default
title: Git & GitHub
parent: Tool Reference
grand_parent: Documentation
nav_order: 4
---

# Git & GitHub Tools

Tools for setting up and managing Git and GitHub integration, including SSH key generation, authentication, and repository management.

**Location:** [`mainmenu/git/`](https://github.com/alistairhendersoninfo/ninja_toolbox/tree/main/mainmenu/git)

## Available Scripts

| Script | Type | Description |
|--------|------|-------------|
| Git & GitHub Setup | install | Complete initial setup with SSH authentication |
| Test GitHub Connection | config | Verify SSH and CLI authentication status |
| Reset Git Credentials | config | Clear authentication state (soft or hard reset) |
| Push to GitHub Repo | config | Create a GitHub repo and push a local folder |

## Git & GitHub Setup

Full initial configuration:

1. Installs `git` and GitHub CLI (`gh`)
2. Configures `user.name` and `user.email`
3. Generates ED25519 SSH key
4. Starts ssh-agent and adds key
5. Authenticates with GitHub via browser flow
6. Uploads SSH key to GitHub
7. Tests SSH connection

**Check:** `gh auth status` and `~/.ssh/id_ed25519`

## Test GitHub Connection

Runs five checks:

1. SSH key file exists
2. SSH agent running with keys loaded
3. GitHub CLI authenticated
4. Git global config set
5. SSH connection to `git@github.com`

## Reset Git Credentials

Two modes:

- **`reset`** -- Clears `gh` session, git config, and credential cache. Keeps SSH keys.
- **`destroy`** -- Everything above, plus removes SSH keys entirely.

## Push to GitHub Repo

Interactive script that:

1. Verifies `gh` is installed and authenticated
2. Gets folder path, repo name, visibility, and description
3. Initialises git if needed
4. Creates `.gitignore` and `README.md` if missing
5. Creates GitHub repo and pushes

## Common Workflows

### First-Time Setup

```
ninjamenu > Git > Git & GitHub Setup
ninjamenu > Git > Test GitHub Connection
```

### Re-authenticate After Token Expiry

```
ninjamenu > Git > Reset Git Credentials (choose "reset")
ninjamenu > Git > Git & GitHub Setup
```

## Technical Details

- All authentication uses SSH (ED25519 keys), not HTTPS tokens
- GitHub CLI uses OAuth token stored in `~/.config/gh/hosts.yml`
- SSH keys are created without a passphrase for automation (add one manually with `ssh-keygen -p` if needed)
- Scripts are designed to be idempotent -- running setup twice won't break anything
