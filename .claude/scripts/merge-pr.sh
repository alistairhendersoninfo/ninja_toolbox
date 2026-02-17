#!/bin/bash
# merge-pr.sh — Pre-check and merge a pull request
# Usage: merge-pr.sh <pr-number> [--squash|--merge|--rebase] [--admin]
# Generic: derives repo owner/name from git remote. Works for any user or machine.

set -uo pipefail

# --- Argument parsing ---
PR_NUMBER=""
STRATEGY="--squash"
USE_ADMIN=""

for arg in "$@"; do
    case "$arg" in
        --squash|--merge|--rebase)
            STRATEGY="$arg"
            ;;
        --admin)
            USE_ADMIN="--admin"
            ;;
        *)
            if [[ -z "$PR_NUMBER" && "$arg" =~ ^[0-9]+$ ]]; then
                PR_NUMBER="$arg"
            fi
            ;;
    esac
done

# --- Derive repo info ---
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
OWNER="$(echo "$OWNER_REPO" | cut -d'/' -f1)"
REPO="$(echo "$OWNER_REPO" | cut -d'/' -f2)"
echo "Repo: $OWNER/$REPO"

# --- Check gh CLI ---
if ! gh auth status >/dev/null 2>&1; then
    echo "ERROR: gh CLI is not authenticated. Run: gh auth login"
    exit 1
fi

# --- Identify PR ---
if [[ -z "$PR_NUMBER" ]]; then
    echo "Looking for PR on current branch..."
    PR_JSON="$(gh pr view --json number,title 2>/dev/null || true)"
    if [[ -n "$PR_JSON" ]]; then
        PR_NUMBER="$(echo "$PR_JSON" | gh pr view --json number --jq '.number' 2>/dev/null || true)"
    fi
fi

if [[ -z "$PR_NUMBER" ]]; then
    echo "ERROR: No PR number provided and no PR found for current branch."
    echo "Usage: merge-pr.sh <pr-number> [--squash|--merge|--rebase] [--admin]"
    echo ""
    echo "Open PRs:"
    gh pr list --state open
    exit 1
fi

# --- Pre-merge checks ---
echo ""
echo "==> Running pre-merge checks for PR #$PR_NUMBER..."
echo ""

PR_DATA="$(gh pr view "$PR_NUMBER" --json number,title,state,headRefName,baseRefName,isDraft,mergeable,reviewDecision 2>/dev/null)"
if [[ -z "$PR_DATA" ]]; then
    echo "ERROR: Could not fetch PR #$PR_NUMBER"
    exit 1
fi

PR_TITLE="$(echo "$PR_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('title',''))" 2>/dev/null)"
PR_STATE="$(echo "$PR_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('state',''))" 2>/dev/null)"
PR_HEAD="$(echo "$PR_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('headRefName',''))" 2>/dev/null)"
PR_BASE="$(echo "$PR_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('baseRefName',''))" 2>/dev/null)"
PR_DRAFT="$(echo "$PR_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('isDraft',False))" 2>/dev/null)"
PR_MERGEABLE="$(echo "$PR_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('mergeable',''))" 2>/dev/null)"
PR_REVIEW="$(echo "$PR_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('reviewDecision',''))" 2>/dev/null)"

echo "PR #$PR_NUMBER: $PR_TITLE"
echo "Branch: $PR_HEAD -> $PR_BASE"
echo "State: $PR_STATE"
echo ""

# Check if already merged
if [[ "$PR_STATE" == "MERGED" ]]; then
    echo "PR #$PR_NUMBER is already merged."
    exit 0
fi

if [[ "$PR_STATE" == "CLOSED" ]]; then
    echo "ERROR: PR #$PR_NUMBER is closed (not merged)."
    exit 1
fi

# Status checks
PASS="[PASS]"
FAIL="[FAIL]"
WARN="[WARN]"

echo "Check              Status"
echo "-----------------------------------------------"

# Draft
if [[ "$PR_DRAFT" == "True" ]]; then
    echo "$WARN Draft           Yes (still a draft)"
else
    echo "$PASS Draft           No (ready for review)"
fi

# Reviews
if [[ "$PR_REVIEW" == "APPROVED" ]]; then
    echo "$PASS Reviews         Approved"
elif [[ "$PR_REVIEW" == "CHANGES_REQUESTED" ]]; then
    echo "$FAIL Reviews         Changes requested"
elif [[ -z "$PR_REVIEW" ]]; then
    echo "$WARN Reviews         No reviews yet"
else
    echo "$WARN Reviews         $PR_REVIEW"
fi

# Mergeable
if [[ "$PR_MERGEABLE" == "MERGEABLE" ]]; then
    echo "$PASS Conflicts       None"
elif [[ "$PR_MERGEABLE" == "CONFLICTING" ]]; then
    echo "$FAIL Conflicts       Has merge conflicts"
else
    echo "$WARN Conflicts       $PR_MERGEABLE"
fi

# CI checks
CI_STATUS="$(gh pr checks "$PR_NUMBER" 2>/dev/null || echo "no checks")"
if echo "$CI_STATUS" | grep -q "fail"; then
    echo "$FAIL CI checks       Some checks failed"
elif echo "$CI_STATUS" | grep -q "pass"; then
    echo "$PASS CI checks       All passed"
elif echo "$CI_STATUS" | grep -q "no checks"; then
    echo "$WARN CI checks       No checks configured"
else
    echo "$WARN CI checks       Pending"
fi

# Diff stats
DIFF_STAT="$(gh pr diff "$PR_NUMBER" --stat 2>/dev/null | tail -1 || echo "unknown")"
echo "       Files          $DIFF_STAT"

echo ""

# --- Block on conflicts ---
if [[ "$PR_MERGEABLE" == "CONFLICTING" ]]; then
    echo "ERROR: Cannot merge — resolve conflicts first."
    exit 1
fi

# --- Auto-detect admin if not specified ---
if [[ -z "$USE_ADMIN" ]]; then
    IS_ADMIN="$(gh api "repos/$OWNER/$REPO" --jq '.permissions.admin' 2>/dev/null || echo "false")"
    if [[ "$IS_ADMIN" == "true" ]]; then
        USE_ADMIN="--admin"
        echo "Admin permissions detected — using admin merge."
    fi
fi

# --- Merge ---
echo ""
echo "==> Merging PR #$PR_NUMBER with strategy: $STRATEGY $USE_ADMIN..."
# shellcheck disable=SC2086
gh pr merge "$PR_NUMBER" $STRATEGY --delete-branch $USE_ADMIN || {
    echo ""
    echo "ERROR: Merge failed."
    echo "Possible causes:"
    echo "  - Branch protection requires approvals"
    echo "  - CI checks have not passed"
    echo "  - Merge conflicts"
    echo ""
    echo "Try: gh pr merge $PR_NUMBER $STRATEGY --delete-branch --admin"
    exit 1
}
echo "    Merged."

# --- Return to main and clean up ---
echo ""
echo "==> Returning to main..."
git checkout main 2>/dev/null || true
git pull origin main || true

# Delete local branch if it still exists
if git show-ref --verify --quiet "refs/heads/$PR_HEAD" 2>/dev/null; then
    git branch -d "$PR_HEAD" 2>/dev/null || git branch -D "$PR_HEAD" 2>/dev/null || true
    echo "    Local branch '$PR_HEAD' deleted."
fi

# Prune stale remote tracking refs
git remote prune origin 2>/dev/null || true

# --- Done ---
echo ""
echo "================================================"
echo "  PR #$PR_NUMBER merged to main."
echo "  Strategy: $STRATEGY"
echo "  Branch '$PR_HEAD' deleted (local + remote)."
echo "================================================"
