---
name: approve-pr
description: Approve a pull request using admin credentials (only approves the specific PR being worked on)
argument-hint: [pr-number]
disable-model-invocation: true
allowed-tools: Bash, AskUserQuestion
---

# Approve PR Workflow

You are approving a specific pull request for the ninja_toolbox project. This skill only approves the single PR specified — it does NOT bulk-approve or approve other PRs.

## Safety rules
- ONLY approve the PR number explicitly provided or detected from the current branch
- NEVER approve multiple PRs in one run
- ALWAYS show the user exactly what they are approving before doing it
- Verify the authenticated user has admin/write access before attempting

## Step 1: Identify the PR

If `$ARGUMENTS` is provided, use that as the PR number. Otherwise detect from current branch:

```bash
gh pr view --json number,title,state,headRefName,isDraft 2>&1
```

If no PR found, list open PRs and ask which one:
```bash
gh pr list --state open
```

## Step 2: Verify identity and permissions

Check who is authenticated:
```bash
gh auth status
```

Check if the user has admin access:
```bash
gh api repos/{owner}/{repo} --jq '.permissions.admin'
```

If not admin, stop and inform the user they cannot self-approve.

## Step 3: Show PR summary for confirmation

Display:
- PR number and title
- Branch name
- Number of commits
- Files changed (names only)
- Any open review comments/issues

```bash
gh pr view <number> --json title,headRefName,commits,files,reviewDecision,comments
gh pr diff <number> --name-only
```

Then use AskUserQuestion to confirm:

**Question: Approve PR #<number>: "<title>"?**
- **Yes, approve** — submit an approval review for this PR only
- **No, don't approve** — cancel without approving

## Step 4: Submit the approval

```bash
gh pr review <number> --approve --body "Approved by admin via approve-pr skill.

Reviewed: $(gh pr diff <number> --name-only | wc -l | tr -d ' ') files
Branch: <branch-name>"
```

## Step 5: Confirm result

Check the review status after approval:
```bash
gh pr view <number> --json reviewDecision --jq '.reviewDecision'
```

Print confirmation:
- PR number approved
- Current review status (should now show APPROVED)
- Remind the user they can now run `/merge-pr` to merge

## Error handling
- If the user is not an admin, explain they need admin access to self-approve
- If GitHub rejects the approval (e.g. can't approve your own PR on some plans), explain the limitation and suggest adding a collaborator or adjusting branch protection
- If the PR is already approved, just say so
- If the PR is closed/merged, inform the user
