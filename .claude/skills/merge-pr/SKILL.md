---
name: merge-pr
description: Check PR status, resolve issues, and merge a pull request
argument-hint: [pr-number]
disable-model-invocation: true
allowed-tools: Bash, Read, AskUserQuestion
---

# Merge PR Workflow

You are merging a pull request for the ninja_toolbox project.

## Step 1: Identify the PR

If `$ARGUMENTS` is provided, use that as the PR number. Otherwise, check if the current branch has an open PR:

```bash
gh pr view --json number,title,state,headRefName,baseRefName,reviewDecision,statusCheckRollup,mergeable,isDraft,body 2>&1
```

If no PR is found, list open PRs and ask the user which one:
```bash
gh pr list --state open
```

## Step 2: Run pre-merge checks

Display a clear status report. For each check, show a pass/fail indicator:

### 2a. Draft status
```bash
gh pr view <number> --json isDraft --jq '.isDraft'
```
If the PR is still a draft, ask the user if they want to mark it ready:
```bash
gh pr ready <number>
```

### 2b. Review status
```bash
gh pr view <number> --json reviewDecision --jq '.reviewDecision'
```
Show whether reviews are approved, changes requested, or pending.

### 2c. CI / status checks
```bash
gh pr view <number> --json statusCheckRollup --jq '.statusCheckRollup'
```
Show pass/fail/pending for each check.

### 2d. Merge conflicts
```bash
gh pr view <number> --json mergeable --jq '.mergeable'
```
If CONFLICTING, warn the user and explain they need to resolve conflicts before merging. Do NOT attempt to force merge.

### 2e. Files changed summary
```bash
gh pr diff <number> --stat
```

## Step 3: Present the status summary

Print a table like:

```
PR #<number>: <title>
Branch: <head> -> <base>

Check              Status
─────────────────────────
Draft              No (ready)
Reviews            Approved (1/1)
CI checks          Passed
Merge conflicts    None
Files changed      5 files (+309 -2)
```

## Step 4: If all checks pass, ask merge strategy

Use AskUserQuestion to ask:

**Question: How do you want to merge this PR?**
- **Merge commit** — keeps all commits, adds a merge commit (best for feature branches with meaningful commit history)
- **Squash and merge** — combines all commits into one (best for cleaning up messy history)
- **Rebase and merge** — replays commits on top of base (best for linear history)
- **Don't merge yet** — cancel and go back to development

## Step 5: Execute the merge

Based on the answer, run:
- Merge commit: `gh pr merge <number> --merge`
- Squash: `gh pr merge <number> --squash`
- Rebase: `gh pr merge <number> --rebase`

After merging, also:
```bash
# Switch back to main and pull
git checkout main
git pull origin main
```

## Step 6: Ask about branch cleanup

Use AskUserQuestion to ask:

**Question: Delete the feature branch?**
- **Yes, delete remote and local** — clean up fully
- **Yes, delete remote only** — keep local copy
- **No, keep the branch** — leave everything as is

Execute accordingly:
- Remote: `gh pr merge` with `--delete-branch` or `git push origin --delete <branch>`
- Local: `git branch -d <branch>`

## Step 7: Summary

Print final summary:
- PR number and title
- Merge method used
- Branch cleanup status
- Current branch (should be main)

## Error handling

- If branch protection blocks the merge (needs approvals), explain clearly what's needed
- If there are conflicts, do NOT force merge — tell the user to resolve them
- If CI is failing, warn but let the user decide whether to proceed
- If the PR is already merged, just say so and skip
