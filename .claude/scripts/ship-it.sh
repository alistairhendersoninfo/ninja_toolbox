#!/bin/bash
# ship-it.sh — Full PR lifecycle: sync main → branch → stage → commit → push → PR → merge → cleanup
# Usage: ship-it.sh <branch-name> <commit-message>
# Generic: derives repo owner/name from git remote. Works for any user or machine.

set -uo pipefail

# --- Argument validation ---
BRANCH="${1:-}"
MESSAGE="${2:-}"

if [[ -z "$BRANCH" || -z "$MESSAGE" ]]; then
    echo "ERROR: Missing arguments"
    echo "Usage: ship-it.sh <branch-name> <commit-message>"
    echo "Example: ship-it.sh docs/add-readmes \"docs: add missing README files\""
    exit 1
fi

# --- Derive repo info from git remote ---
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "$REPO_ROOT" ]]; then
    echo "ERROR: Not inside a git repository"
    exit 1
fi
cd "$REPO_ROOT"

REMOTE_URL="$(git remote get-url origin 2>/dev/null)"
if [[ -z "$REMOTE_URL" ]]; then
    echo "ERROR: No 'origin' remote found"
    exit 1
fi

# Extract owner/repo from HTTPS or SSH URL
OWNER_REPO="$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')"
OWNER="$(echo "$OWNER_REPO" | cut -d'/' -f1)"
REPO="$(echo "$OWNER_REPO" | cut -d'/' -f2)"
echo "Repo: $OWNER/$REPO"

# --- Check gh CLI is authenticated ---
if ! gh auth status >/dev/null 2>&1; then
    echo "ERROR: gh CLI is not authenticated. Run: gh auth login"
    exit 1
fi

# --- Step 1: Sync main ---
echo ""
echo "==> Step 1: Syncing main..."
git checkout main 2>/dev/null || { echo "ERROR: Could not checkout main"; exit 1; }
git pull origin main || { echo "ERROR: Could not pull origin main"; exit 1; }
echo "    Main is up to date."

# --- Step 2: Create branch ---
echo ""
echo "==> Step 2: Creating branch '$BRANCH'..."
if git show-ref --verify --quiet "refs/heads/$BRANCH" 2>/dev/null; then
    echo "    Branch '$BRANCH' already exists locally. Deleting..."
    git branch -D "$BRANCH" || { echo "ERROR: Could not delete existing branch"; exit 1; }
fi
git checkout -b "$BRANCH" || { echo "ERROR: Could not create branch '$BRANCH'"; exit 1; }
echo "    On branch '$BRANCH'."

# --- Step 3: Stage and commit ---
echo ""
echo "==> Step 3: Staging and committing..."
git add -A

# Check if there's anything to commit
if git diff --cached --quiet; then
    echo "ERROR: Nothing to commit — working tree is clean."
    git checkout main
    git branch -D "$BRANCH" 2>/dev/null
    exit 1
fi

COMMIT_MSG="$MESSAGE

Co-Authored-By: Claude <noreply@anthropic.com>"

git commit -m "$COMMIT_MSG" || { echo "ERROR: Commit failed"; exit 1; }
echo "    Committed."

# --- Step 4: Push and create PR ---
echo ""
echo "==> Step 4: Pushing and creating PR..."
git push -u origin "$BRANCH" || { echo "ERROR: Push failed"; exit 1; }

# Generate PR body from diff stats
DIFF_STAT="$(git diff main --stat | head -20)"
PR_BODY="## Summary
$DIFF_STAT

Generated with [Claude Code](https://claude.com/claude-code)"

PR_URL="$(gh pr create --title "$MESSAGE" --body "$PR_BODY" 2>&1)"
if [[ $? -ne 0 ]]; then
    echo "ERROR: PR creation failed: $PR_URL"
    exit 1
fi
echo "    PR created: $PR_URL"

# --- Step 5: Merge ---
echo ""
echo "==> Step 5: Merging PR..."

# Extract PR number from URL
PR_NUMBER="$(echo "$PR_URL" | grep -oE '[0-9]+$')"

# Check if user has admin permissions
IS_ADMIN="$(gh api "repos/$OWNER/$REPO" --jq '.permissions.admin' 2>/dev/null || echo "false")"

if [[ "$IS_ADMIN" == "true" ]]; then
    gh pr merge "$PR_NUMBER" --squash --delete-branch --admin || { echo "ERROR: Merge failed"; exit 1; }
else
    gh pr merge "$PR_NUMBER" --squash --delete-branch || {
        echo "ERROR: Merge failed. You may need admin permissions or PR approvals."
        echo "The PR is still open at: $PR_URL"
        echo "Merge manually with: gh pr merge $PR_NUMBER --squash --delete-branch"
        exit 1
    }
fi
echo "    Merged and branch deleted."

# --- Step 6: Return to main and clean up ---
echo ""
echo "==> Step 6: Returning to main..."
git checkout main || { echo "ERROR: Could not checkout main"; exit 1; }
git pull origin main || { echo "ERROR: Could not pull main"; exit 1; }

# Delete local branch if it still exists
if git show-ref --verify --quiet "refs/heads/$BRANCH" 2>/dev/null; then
    git branch -d "$BRANCH" 2>/dev/null || git branch -D "$BRANCH" 2>/dev/null || true
    echo "    Local branch '$BRANCH' deleted."
fi

# Prune stale remote tracking refs
git remote prune origin 2>/dev/null || true

# --- Done ---
echo ""
echo "================================================"
echo "  Shipped! PR #$PR_NUMBER merged to main."
echo "  Branch '$BRANCH' deleted (local + remote)."
echo "  $PR_URL"
echo "================================================"
