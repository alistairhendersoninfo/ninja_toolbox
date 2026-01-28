---
name: git-commit
description: "Use when user asks to commit, git commit, push code, save changes, or mentions committing. Provides structured workflow for staging, committing, and pushing git changes."
version: 1.1.0
author: NinjaMenu
tags: [git, commit, version-control]
---

# Git Commit Skill

Structured workflow for committing code changes to git.

## Trigger Phrases

- "commit", "git commit"
- "push code", "push changes"
- "save changes to git"
- "commit and push"

## Workflow

### Step 1: Gather Information

Run in parallel:
```bash
git status                    # Current state
git diff --stat               # Summary of changes
git log --oneline -5          # Recent commit style
```

### Step 2: Present Changes

Summarize for user:
- Modified files with brief description
- New (untracked) files
- Deleted files
- **WARN** about sensitive files (.env, credentials, keys)

### Step 3: Stage Files

Prefer explicit file names:
```bash
git add <specific-files>
```

**NEVER stage**: `.env`, `*.key`, `credentials.*`, API keys, secrets, node_modules

### Step 4: Commit Message

Good messages:
- 50-72 char subject line
- Describe WHAT and WHY
- Imperative mood ("Add feature" not "Added feature")

Examples:
- `Add user authentication with JWT tokens`
- `Fix null pointer in payment processing`
- `Refactor database connection pooling`

### Step 5: Create Commit

Use heredoc for proper formatting:
```bash
git commit -m "$(cat <<'EOF'
Your commit message here

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

### Step 6: Push (if requested)

```bash
git status                    # Verify success
git push                      # Push to remote
git push -u origin <branch>   # For new branches
```

## Safety Rules

- [ ] No sensitive files (.env, keys, credentials)
- [ ] No large binaries or node_modules
- [ ] Commit message describes changes
- [ ] Never use `--force` without explicit request
- [ ] Never amend unless explicitly asked

## Quick Reference

| Action | Command |
|--------|---------|
| Status | `git status` |
| Changes | `git diff` |
| Stage | `git add <file>` |
| Commit | `git commit -m "msg"` |
| Push | `git push` |
| New branch | `git push -u origin <branch>` |
