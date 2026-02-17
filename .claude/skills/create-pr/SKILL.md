---
name: create-pr
description: Create a new feature branch, PR, and folder structure for developing a new menu script
argument-hint: [feature-name]
disable-model-invocation: false
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# Create PR Workflow

You are setting up a new feature branch with a Pull Request for this project.

## Current repo state
- Remote: !`git remote -v | head -1`
- Current branch: !`git branch --show-current`
- Repo root: !`git rev-parse --show-toplevel`

## Step 1: Gather information

Use the AskUserQuestion tool to ask the user ALL of the following in a single call:

**Question 1 — Menu category:**
Which mainmenu category does this feature belong to? Options based on existing folders:
!`ls -d mainmenu/*/  | sed 's|mainmenu/||;s|/||'`
Include an "Other (new category)" option.

**Question 2 — Feature type:**
What type of script is this? Options: "Install script (installs a tool)", "Config script (run-only utility)", "Bug fix (fixing existing script)", "Enhancement (improving existing script)"

**Question 3 — Needs root?**
Does this script require root/sudo privileges? Options: "Yes", "No"

After the user answers, ask a second round of questions with AskUserQuestion:

**Question 4 — Tool name:**
Ask: "What is the name of the tool/feature?" (free text via Other option — provide sensible placeholder options based on the category they chose)

**Question 5 — Description:**
Ask: "One-line description of what this does?" (free text via Other)

## Step 2: Determine the branch name

Use the answers to construct a branch name following this pattern:
- `feature/<category>-<tool-name>` for new installs (e.g., `feature/network-zenmap`)
- `fix/<category>-<tool-name>` for bug fixes
- `enhance/<category>-<tool-name>` for enhancements

## Step 3: Create the folder structure and files

Based on the answers, create files using the project templates and conventions from CLAUDE.md:

### For a NEW install/config script:

1. **The script itself**: `mainmenu/<category>/<tool-name>.sh`
   - Use the script template from `.docs/templates/script_template.sh` as the base
   - Fill in the YAML header with: name, description, type (install/config), root (true/false), order (pick next available number in that category), check_command, tags
   - Leave the installation logic section with clear TODO comments for the developer

2. **Update folder README**: If `mainmenu/<category>/README.md` exists, add the new script to its listing

3. **Create a development notes file**: `mainmenu/<category>/<tool-name>.dev.md`
   - PR description, what needs implementing, acceptance criteria

### For a BUG FIX or ENHANCEMENT:
1. Create a `<tool-name>.dev.md` in the relevant folder with notes on what to fix/change

## Step 4: Create branch and draft PR using the script

Build the PR body with a checklist, then call the create-pr script:

```bash
BODY="## Summary
- <what this PR adds/fixes>
- Category: \`mainmenu/<category>/\`
- Script: \`<tool-name>.sh\`

## Checklist
- [ ] Script has complete YAML header
- [ ] Install logic implemented
- [ ] Uninstall logic implemented
- [ ] check_command verifies installation
- [ ] Tested on target OS
- [ ] Folder README.md updated
- [ ] User manual updated (\`.docs/user_manuals/\`)
- [ ] Technical manual updated (\`.docs/technical_manuals/\`)

## Test Plan
- [ ] Run \`bash mainmenu/<category>/<tool-name>.sh install\`
- [ ] Verify \`<check_command>\` succeeds
- [ ] Run \`bash mainmenu/<category>/<tool-name>.sh uninstall\`
- [ ] Verify tool is removed
- [ ] Menu system discovers the script

Generated with [Claude Code](https://claude.com/claude-code)"

.claude/scripts/create-pr.sh "<branch-name>" "<type>(<category>): add <tool-name>" "$BODY"
```

The script handles: sync main, create branch, stage files, commit, push, and create a draft PR.

## Step 5: Summary

Print a clear summary:
- Branch name
- PR URL (from script output)
- Files created
- Next steps for the developer (implement the TODO sections, push commits, mark PR ready for review)

## Error handling

If the script fails:
1. Read the error output
2. Fix the issue (auth, branch conflict, etc.)
3. Re-run the script, or fix `.claude/scripts/create-pr.sh` if the script itself has a bug
