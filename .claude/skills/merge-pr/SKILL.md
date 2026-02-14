---
name: merge-pr
description: Check PR status, resolve issues, and merge a pull request
argument-hint: [pr-number]
disable-model-invocation: true
allowed-tools: Bash, Read, AskUserQuestion
---

# Merge PR Workflow

You are merging a pull request for this project.

## Step 1: Identify the PR

If `$ARGUMENTS` is provided, use that as the PR number. Otherwise, ask the user:

```bash
gh pr list --state open
```

Then use AskUserQuestion to let them pick which PR.

## Step 2: Ask merge strategy

Use AskUserQuestion to ask:

**Question: How do you want to merge this PR?**
- **Squash and merge (Recommended)** — combines all commits into one (clean history)
- **Merge commit** — keeps all commits, adds a merge commit
- **Rebase and merge** — replays commits on top of base (linear history)
- **Don't merge yet** — cancel

## Step 3: Run the merge script

Map the user's choice to a flag and call the script:

```bash
# Squash:
.claude/scripts/merge-pr.sh <pr-number> --squash

# Merge commit:
.claude/scripts/merge-pr.sh <pr-number> --merge

# Rebase:
.claude/scripts/merge-pr.sh <pr-number> --rebase
```

The script handles:
1. Pre-merge checks (draft status, reviews, CI, conflicts, diff stats)
2. Prints a status table
3. Auto-detects admin permissions
4. Merges with the chosen strategy
5. Deletes the branch
6. Returns to main and pulls

## Step 4: Summary

After the script completes, print:
- PR number and title
- Merge method used
- Branch cleanup status
- Current branch (should be main)

## Error handling

If the script fails:
1. Read the error output — it explains the cause (branch protection, conflicts, CI failures)
2. If it's a fixable issue, fix it and re-run the script
3. If the script itself has a bug, edit `.claude/scripts/merge-pr.sh`, fix it, and re-run
4. If the PR is already merged, the script exits cleanly
