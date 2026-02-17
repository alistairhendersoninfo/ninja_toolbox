---
name: review-tasks
description: Read code review comments from a PR and create todo tasks for each issue
argument-hint: [pr-number]
disable-model-invocation: false
allowed-tools: Bash, Read, TaskCreate, TaskUpdate, TaskList, AskUserQuestion
---

# Review Tasks Workflow

You read code review comments/issues from a pull request and create actionable todo tasks for each one.

## Step 1: Identify the PR

If `$ARGUMENTS` is provided, use that as the PR number. Otherwise detect from current branch:

```bash
gh pr view --json number,title,headRefName 2>&1
```

## Step 2: Fetch all review comments

Get the PR review summary:
```bash
gh api repos/{owner}/{repo}/pulls/<number>/reviews
```

Get inline review comments (the actual code-level feedback):
```bash
gh api repos/{owner}/{repo}/pulls/<number>/comments
```

Also get general PR comments:
```bash
gh pr view <number> --comments
```

## Step 3: Parse and categorise each issue

For each review comment, extract:
- **Severity**: critical, high, medium, low (from the comment body or infer from context)
- **File**: which file the comment is on
- **Line**: which line(s)
- **Issue**: what the problem is (one-line summary)
- **Suggestion**: the suggested fix if one was provided (look for ```suggestion blocks)
- **Reviewer**: who left the comment

## Step 4: Display summary table

Print a table of all issues found:

```
PR #<number> Code Review Issues
────────────────────────────────────────────────
#  Severity  File                          Line  Issue
1  critical  nmap-tools-bundle.sh          133   Homebrew must not run as root on macOS
2  high      nmap-tools-bundle.sh          71    sed -i not portable on macOS
3  medium    nmap-tools-bundle.sh          184   Debian uninstall missing pipx removal
4  medium    nmap-tools-bundle.sh          189   macOS uninstall missing pipx/libxslt removal
```

## Step 5: Create tasks

For EACH issue, use TaskCreate to create a task:

- **subject**: `Fix: <one-line issue summary>` (imperative form)
- **description**: Include:
  - Severity level
  - File path and line number
  - Full description of the problem
  - The suggested fix (code block) if provided by the reviewer
  - Link to the review comment
- **activeForm**: `Fixing <short issue description>`

After creating all tasks, set up dependencies if any exist (e.g. critical issues should block lower-severity ones if they affect the same code).

## Step 6: Summary

Print:
- Total issues found
- Breakdown by severity
- Task IDs created
- Suggest the user work through them in severity order (critical first)

Remind the user that after fixing all issues, they should push the changes to the branch so the PR updates, then run `/approve-pr` when ready.
