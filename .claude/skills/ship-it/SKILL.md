---
name: ship-it
description: "Ship changes: branch, commit, push, PR, merge — all in one command"
argument-hint: <branch-name> <commit-message>
disable-model-invocation: true
allowed-tools: Bash, Read, AskUserQuestion
---

# Ship It

Ship all pending changes through a PR. Takes two arguments: branch name and commit message.

**Usage:** `/ship-it fix/my-branch "fix: describe the change"`

If `$ARGUMENTS` contains both a branch name and a quoted commit message, skip straight to execution with NO questions asked.

If `$ARGUMENTS` is empty or incomplete, use AskUserQuestion to ask ONE question for the missing info.

## Execution

Run these commands in sequence. If any step fails, stop and report the error.

### Step 1: Sync main
```bash
git checkout main
git pull origin main
```

### Step 2: Create branch
```bash
git checkout -b <branch-name>
```
If the branch already exists, delete it first: `git branch -D <branch-name>` then retry.

### Step 3: Stage and commit
```bash
git add -A
git reset HEAD -- ship-this.sh 2>/dev/null || true
git commit -m "<commit-message>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```
If nothing to commit, STOP: "Nothing to ship — working tree is clean."

### Step 4: Push and create PR
```bash
git push -u origin <branch-name>
gh pr create --title "<commit-message>" --body "## Summary
$(git diff main --stat | head -20)

Generated with [Claude Code](https://claude.com/claude-code)"
```

### Step 5: Merge
```bash
gh pr merge --squash --delete-branch --admin
git checkout main
git pull origin main
```

### Step 6: Print summary
```
Shipped! PR merged to main.
```
