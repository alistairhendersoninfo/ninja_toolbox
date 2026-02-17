---
name: approve-pr
description: Admin self-review gate — verifies all review issues are resolved then clears PR for merge
argument-hint: [pr-number]
disable-model-invocation: false
allowed-tools: Bash, Read, AskUserQuestion
---

# Approve PR Workflow (Admin Self-Review)

GitHub does not allow you to approve your own PRs. Instead, this skill acts as a
self-review gate: it verifies you are admin, checks that all code review issues
have been addressed, and then confirms the PR is clear for you to merge using
your admin bypass.

**How it works:**
- Regular contributors: still need 1 approval from someone else to merge
- Admin (you): go through the same review process, but can merge via admin bypass
  once this skill confirms all issues are resolved

This skill only processes the single PR specified — it does NOT affect other PRs.

## Step 1: Identify the PR

If `$ARGUMENTS` is provided, use that as the PR number. Otherwise detect from current branch:

```bash
gh pr view --json number,title,state,headRefName,isDraft 2>&1
```

If no PR found, list open PRs and ask which one:
```bash
gh pr list --state open
```

## Step 2: Verify admin access

```bash
gh auth status
gh api repos/{owner}/{repo} --jq '.permissions.admin'
```

If not admin, STOP. Tell the user:
> "You are not an admin on this repo. You need another contributor to approve your PR.
> Ask a collaborator to review, or use `/merge-pr` if the PR already has approval."

## Step 3: Check for outstanding review comments

Fetch all review comments:
```bash
gh api repos/{owner}/{repo}/pulls/<number>/comments
```

Fetch the review summary:
```bash
gh api repos/{owner}/{repo}/pulls/<number>/reviews
```

Parse the comments and check:
- Are there **unresolved review comments** (suggestions not applied, issues not fixed)?
- Have new commits been pushed **after** the review was submitted?

For each review comment, check if the issue was addressed by looking at:
1. Whether the suggested code change was applied in a later commit
2. Whether a reply acknowledges and addresses the feedback

## Step 4: Display the review status

Print a clear summary:

```
PR #<number>: <title>
Branch: <head> -> <base>
Commits: <count>

Review Issues Status
─────────────────────────────────────────
#  Severity  Issue                          Status
1  critical  <description>                  FIXED / OPEN
2  high      <description>                  FIXED / OPEN
3  medium    <description>                  FIXED / OPEN
```

Also show:
- Files changed (names only)
- Whether the PR is still a draft

## Step 5: Gate decision

**If ALL issues are FIXED:**

Print:
```
All review issues have been addressed.
As admin, you can merge this PR using your admin bypass.
```

Use AskUserQuestion to confirm:

**Question: All review issues resolved. Proceed to merge PR #<number>?**
- **Yes, merge now** — run the merge workflow immediately
- **No, not yet** — stop here, the user can run `/merge-pr` later

If "Yes, merge now": proceed directly to Step 6.

**If any issues are still OPEN:**

Print the list of unresolved issues with file, line, and what needs fixing.

Then use AskUserQuestion to let the admin decide:

**Question: There are <N> unresolved review issues. What do you want to do?**
- **Override and merge anyway** — acknowledge open issues and merge as-is (admin override)
- **Go back and fix** — stop here, fix the issues, push, and run approve-pr again

If "Override and merge anyway": proceed to Step 6. After merging, the admin review
comment (Step 7) MUST list the overridden issues so there is a clear record of what
was knowingly skipped.

## Step 6: Merge (if approved)

If the user confirmed merge, ask merge strategy:

**Question: How do you want to merge?**
- **Squash and merge (Recommended)** — combines all commits into one clean commit
- **Merge commit** — keeps all commits, adds a merge commit
- **Rebase and merge** — replays commits on top of base

Execute the merge:
```bash
gh pr merge <number> --squash   # or --merge or --rebase
```

After merging:
```bash
git checkout main
git pull origin main
```

Ask about branch cleanup:

**Question: Delete the feature branch?**
- **Yes, delete both** — remote and local cleanup
- **No, keep it** — leave the branch

Print final summary:
- PR merged successfully
- Merge method used
- Branch cleanup status
- Current branch

## Step 7: Leave an admin review comment

After merge, leave a comment on the PR documenting the admin review:
```bash
gh pr comment <number> --body "Admin self-review completed.

All code review issues were verified as resolved before merge.
Merged via admin bypass (approve-pr skill).

Issues addressed:
- <list each issue and how it was fixed>"
```
