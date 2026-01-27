# Git & GitHub - User Guide

## Overview

The Git menu provides tools for setting up and managing Git and GitHub integration on your system. It handles SSH key generation, GitHub authentication, and repository management.

## Available Tools

### Git & GitHub Setup

**What it does:** Complete initial setup for Git and GitHub, including SSH key creation and authentication.

**How to use:**
1. Run `ninjamenu`
2. Navigate to Git → Git & GitHub Setup
3. Enter your name and email when prompted
4. Follow browser authentication for GitHub
5. SSH key is automatically created and added to GitHub

**What gets installed:**
- Git (if not present)
- GitHub CLI (`gh`)
- SSH key pair (`~/.ssh/id_ed25519`)

### Test GitHub Connection

**What it does:** Verifies your SSH connection to GitHub is working.

**How to use:**
1. Run `ninjamenu`
2. Navigate to Git → Test GitHub Connection
3. Review the connection status

**Checks performed:**
- SSH key exists
- SSH agent running
- GitHub CLI authenticated
- Git user configured
- SSH connection to GitHub

### Reset Git Credentials

**What it does:** Clears authentication without destroying your SSH keys.

**How to use:**
1. Run `ninjamenu`
2. Navigate to Git → Reset Git Credentials
3. Type `reset` to clear credentials (keeps SSH keys)
4. Type `destroy` to also remove SSH keys

**What gets cleared:**
- GitHub CLI session
- Git global user config
- Credential cache

### Push to GitHub Repo

**What it does:** Creates a GitHub repository and pushes a local folder.

**How to use:**
1. Run `ninjamenu`
2. Navigate to Git → Push to GitHub Repo
3. Enter the folder path to push
4. Enter repository name (default: folder name)
5. Choose public or private
6. Enter description (optional)

**Creates automatically:**
- README.md (if missing)
- .gitignore (if missing)
- GitHub repository
- Initial commit

## Common Tasks

### First-Time Setup

1. Run Git & GitHub Setup
2. Enter your name and email
3. Complete GitHub browser authentication
4. Run Test GitHub Connection to verify

### Push an Existing Project

1. Ensure you've run Git & GitHub Setup first
2. Run Push to GitHub Repo
3. Enter the path to your project folder
4. Choose a repository name and visibility

### Re-authenticate After Token Expiry

1. Run Reset Git Credentials (type `reset`)
2. Run Git & GitHub Setup again
3. Complete browser authentication

## Troubleshooting

### Permission denied (publickey)

**Symptom:** SSH connection fails with permission denied

**Solution:**
1. Run Test GitHub Connection to see your public key
2. Add the key at https://github.com/settings/keys
3. Or run Git & GitHub Setup to re-authenticate

### Already authenticated error

**Symptom:** GitHub CLI says already authenticated but commands fail

**Solution:**
1. Run Reset Git Credentials (type `reset`)
2. Run Git & GitHub Setup again

### Push rejected

**Symptom:** Push fails because remote has changes

**Solution:**
- The script will ask if you want to force push
- Only use force push if you're sure you want to overwrite remote

## FAQ

**Q: Where is my SSH key stored?**
A: `~/.ssh/id_ed25519` (private) and `~/.ssh/id_ed25519.pub` (public)

**Q: Can I use an existing SSH key?**
A: Yes, when prompted to create a new key, choose No to keep your existing one.

**Q: What's the difference between reset and destroy?**
A: `reset` clears authentication but keeps SSH keys. `destroy` removes everything including SSH keys.

## See Also

- [Technical Manual](../technical_manuals/git.md)
