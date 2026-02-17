---
name: pr-status
description: "Show open PRs and issues — summary or detailed view"
argument-hint: "[pr-number | issue-number]"
disable-model-invocation: false
allowed-tools: Bash, Read
---

# PR Status

Show the status of open pull requests and issues. Three modes:

- **Summary** (no arguments): Table of all open PRs + table of all open issues
- **PR Detail** (PR number): Full breakdown of a specific PR
- **Issue Detail** (`issue <number>`): Full breakdown of a specific issue

**Usage:**
- `/pr-status` — show all open PRs and issues
- `/pr-status 23` — show detailed view of PR #23
- `/pr-status issue 20` — show detailed view of issue #20

## Execution

### If `$ARGUMENTS` is empty — Summary Mode

Run these two commands:

```bash
gh pr list --state open --json number,title,headRefName,author,createdAt,labels,reviewDecision,statusCheckRollup,additions,deletions,changedFiles --limit 50
```

```bash
gh issue list --state open --json number,title,labels,author,createdAt,updatedAt --limit 50
```

**Present open PRs** as a markdown table:

| # | Title | Branch | Author | Created | Files | +/- | Reviews | Checks |
|---|-------|--------|--------|---------|-------|-----|---------|--------|

- **Files**: `changedFiles` count
- **+/-**: `+additions/-deletions`
- **Reviews**: `reviewDecision` (APPROVED, CHANGES_REQUESTED, REVIEW_REQUIRED, or blank)
- **Checks**: Summarise `statusCheckRollup` as PASS/FAIL/PENDING based on check conclusions
- **Created**: Show as relative time (e.g., "2h ago", "3d ago")

If there are no open PRs, say: "No open PRs — everything is merged."

**Present open issues** as a markdown table:

| # | Title | Labels | Author | Created |
|---|-------|--------|--------|---------|

- **Labels**: comma-separated label names, or blank
- **Created**: Show as relative time

If there are no open issues, say: "No open issues."

Show a count summary at the bottom: `X open PR(s), Y open issue(s)`

### If `$ARGUMENTS` contains just a number — PR Detail Mode

Run this command:

```bash
gh pr view <PR_NUMBER> --json number,title,body,headRefName,baseRefName,author,createdAt,updatedAt,labels,reviewDecision,reviewRequests,reviews,statusCheckRollup,additions,deletions,changedFiles,files,comments,mergeable,isDraft,url
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

### If `$ARGUMENTS` contains "issue <number>" — Issue Detail Mode

Run this command:

```bash
gh issue view <ISSUE_NUMBER> --json number,title,body,author,createdAt,updatedAt,labels,comments,state,url
```

Present the full breakdown:

**Header:**
```
Issue #<number>: <title>
<url>
```

**Status Block:**
- State: Open / Closed
- Author: `<login>`
- Created: `<date>` (relative)
- Updated: `<date>` (relative)
- Labels: comma-separated or None

**Description:**
Show the full issue body.

**Comments:**
If there are comments, show them with author and timestamp.
