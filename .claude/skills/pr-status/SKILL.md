---
name: pr-status
description: "Show open PRs — summary table or detailed view of a specific PR"
argument-hint: "[pr-number]"
disable-model-invocation: true
allowed-tools: Bash, Read
---

# PR Status

Show the status of open pull requests. Two modes:

- **Summary** (no arguments): Table of all open PRs with key info
- **Detail** (PR number provided): Full breakdown of a specific PR

**Usage:**
- `/pr-status` — show all open PRs in a summary table
- `/pr-status 23` — show detailed view of PR #23

## Execution

### If `$ARGUMENTS` is empty — Summary Mode

Run the following command to get all open PRs:

```bash
gh pr list --state open --json number,title,headRefName,author,createdAt,labels,reviewDecision,checks,additions,deletions,changedFiles --limit 50
```

Present the results as a markdown table with these columns:

| # | Title | Branch | Author | Created | Files | +/- | Reviews | Checks |
|---|-------|--------|--------|---------|-------|-----|---------|--------|

- **Files**: `changedFiles` count
- **+/-**: `+additions/-deletions`
- **Reviews**: `reviewDecision` (APPROVED, CHANGES_REQUESTED, REVIEW_REQUIRED, or blank)
- **Checks**: Summarise as PASS/FAIL/PENDING based on check conclusions
- **Created**: Show as relative time (e.g., "2h ago", "3d ago")

If there are no open PRs, say: "No open PRs — everything is merged."

Also show a count summary at the bottom: `X open PR(s)`

### If `$ARGUMENTS` contains a PR number — Detail Mode

Run these commands to gather full details:

```bash
gh pr view <PR_NUMBER> --json number,title,body,headRefName,baseRefName,author,createdAt,updatedAt,labels,reviewDecision,reviewRequests,reviews,checks,additions,deletions,changedFiles,files,comments,mergeable,isDraft,url
```

Present the full breakdown:

**Header:**
```
PR #<number>: <title>
<url>
```

**Status Block:**
- State: Open / Draft
- Branch: `<head>` → `<base>`
- Author: `<login>`
- Created: `<date>` (relative)
- Updated: `<date>` (relative)
- Mergeable: Yes/No/Conflicting
- Review: APPROVED / CHANGES_REQUESTED / REVIEW_REQUIRED / None
- Checks: List each check with status (pass/fail/pending)

**Changes:**
- Files changed: `<count>`
- Additions: `+<count>`
- Deletions: `-<count>`
- List all changed files with their status (added/modified/deleted)

**Description:**
Show the full PR body/description.

**Comments:**
If there are comments, show them with author and timestamp.

**Reviews:**
If there are reviews, show reviewer, state, and any body text.
