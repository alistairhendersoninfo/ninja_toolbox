---
name: ship-it
description: "Ship changes: branch, commit, push, PR, merge — all in one command"
argument-hint: <branch-name> <commit-message>
disable-model-invocation: true
allowed-tools: Bash, Read, AskUserQuestion
---

# Ship It

Ship all pending changes through a PR. Takes two arguments: branch name and commit message.

**Usage:** `/ship-it fix/my-branch "fix: describe the change"`

If `$ARGUMENTS` contains both a branch name and a quoted commit message, skip straight to execution with NO questions asked.

If `$ARGUMENTS` is empty or incomplete, use AskUserQuestion to ask ONE question for the missing info.

## Execution

Run the ship-it script. It handles the full lifecycle: sync main, create branch, stage, commit, push, PR, merge, cleanup.

```bash
.claude/scripts/ship-it.sh <branch-name> <commit-message>
```

The script:
1. Syncs main (`git checkout main && git pull`)
2. Creates the branch (deletes existing if needed)
3. Stages all changes (`git add -A`)
4. Commits with message and co-author line
5. Pushes and creates a PR with auto-generated body
6. Detects admin permissions and merges (squash + delete branch)
7. Returns to main and pulls

## Error handling

If the script fails:
1. Read the error output — it explains what went wrong
2. If it's a fixable issue (e.g. auth, conflicts), fix it and re-run the script
3. If the script itself has a bug, edit `.claude/scripts/ship-it.sh`, fix it, and re-run
4. The script is self-contained — no hidden state or side effects between runs

## Print summary

After the script completes successfully, confirm:
```
Shipped! PR merged to main.
```
