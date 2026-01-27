---
name: git-commit
description: This skill should be used when the user asks to "commit", "git commit", "push code", "save changes to git", "commit and push", or mentions committing their work. Provides a structured workflow for staging, committing, and pushing git changes.
version: 1.0.0
---

# Git Commit Skill

This skill provides a structured workflow for committing code changes to git.

## When This Skill Applies

Use this skill when the user wants to:
- Commit their changes to git
- Push code to a remote repository
- Save their work with a commit message
- Stage and commit files

## Workflow

### Step 1: Check Repository Status

Run these commands in parallel to gather information:

```bash
git status
git diff --stat
git log --oneline -5
```

This shows:
- Current branch and status
- Summary of what changed
- Recent commit style for consistency

### Step 2: Present Changes to User

Summarize what will be committed:
- List modified files with brief description of changes
- List new (untracked) files
- List deleted files
- Warn about any sensitive files (.env, credentials, keys)

### Step 3: Stage Files

Stage appropriate files - prefer explicit file names:

```bash
git add <specific-files>
```

**Never stage**: `.env`, `*.key`, `credentials.*`, API keys, secrets

### Step 4: Get Commit Message

If user didn't provide a message, ask for one. Good messages:
- Are concise (50-72 chars subject line)
- Describe WHAT and WHY
- Use imperative mood ("Add feature" not "Added feature")

Examples:
- "Add user authentication with JWT tokens"
- "Fix null pointer in payment processing"
- "Update README with install instructions"

### Step 5: Create the Commit

Use heredoc format for proper message formatting:

```bash
git commit -m "$(cat <<'EOF'
Your commit message here

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### Step 6: Verify and Push

After committing:
```bash
git status                    # Verify commit succeeded
git push                      # Push to remote (if requested)
```

For new branches:
```bash
git push -u origin <branch>
```

## Safety Checklist

Before committing, verify:
- [ ] No sensitive files staged
- [ ] No large binaries accidentally included  
- [ ] Commit message describes the changes
- [ ] All intended files are staged

## Quick Reference

| Action | Command |
|--------|---------|
| Check status | `git status` |
| See changes | `git diff` |
| Stage file | `git add <file>` |
| Stage all | `git add .` |
| Commit | `git commit -m "message"` |
| Push | `git push` |
| Push new branch | `git push -u origin <branch>` |
