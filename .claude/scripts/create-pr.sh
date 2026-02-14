#!/bin/bash
# create-pr.sh — Create a branch and open a draft PR
# Usage: create-pr.sh <branch-name> <title> [body]
# Generic: derives repo owner/name from git remote. Works for any user or machine.

set -uo pipefail

# --- Argument validation ---
BRANCH="${1:-}"
TITLE="${2:-}"
BODY="${3:-}"

if [[ -z "$BRANCH" || -z "$TITLE" ]]; then
    echo "ERROR: Missing arguments"
    echo "Usage: create-pr.sh <branch-name> <title> [body]"
    echo "Example: create-pr.sh feature/network-zenmap \"feat(network): add zenmap\" \"Adds Zenmap GUI scanner\""
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

OWNER_REPO="$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')"
echo "Repo: $OWNER_REPO"

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

# --- Step 3: Stage changes if any ---
echo ""
echo "==> Step 3: Checking for changes to commit..."
git add -A

if git diff --cached --quiet; then
    echo "    No changes to commit. Creating empty branch push..."
    # Push the branch even with no changes (scaffolding PR)
else
    COMMIT_MSG="scaffold: $TITLE

Co-Authored-By: Claude <noreply@anthropic.com>"
    git commit -m "$COMMIT_MSG" || { echo "ERROR: Commit failed"; exit 1; }
    echo "    Changes committed."
fi

# --- Step 4: Push branch ---
echo ""
echo "==> Step 4: Pushing branch..."
git push -u origin "$BRANCH" || { echo "ERROR: Push failed"; exit 1; }
echo "    Branch pushed."

# --- Step 5: Create draft PR ---
echo ""
echo "==> Step 5: Creating draft PR..."

if [[ -z "$BODY" ]]; then
    BODY="## Summary
- Branch: \`$BRANCH\`

## Checklist
- [ ] Implementation complete
- [ ] Documentation updated
- [ ] Tested

Generated with [Claude Code](https://claude.com/claude-code)"
fi

PR_URL="$(gh pr create --draft --title "$TITLE" --body "$BODY" 2>&1)"
if [[ $? -ne 0 ]]; then
    echo "ERROR: PR creation failed: $PR_URL"
    exit 1
fi
echo "    Draft PR created: $PR_URL"

# --- Done ---
echo ""
echo "================================================"
echo "  Branch '$BRANCH' ready with draft PR."
echo "  $PR_URL"
echo "  Push more commits to this branch as you work."
echo "================================================"
