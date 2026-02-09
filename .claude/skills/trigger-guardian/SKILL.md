---
name: trigger-guardian
description: Trigger a Wiki Guardian test run by making a trivial wiki edit and checking the action result
argument-hint: [optional: "spam" to test spam detection]
disable-model-invocation: true
allowed-tools: Bash, Read, AskUserQuestion
---

# Trigger Wiki Guardian

You are triggering a test run of the Wiki Guardian spam detection workflow by making a trivial edit to the wiki.

## Current repo state
- Remote: !`git remote -v | head -1`
- Current branch: !`git branch --show-current`
- Repo root: !`git rev-parse --show-toplevel`

## Step 1: Clone the wiki

Clone the wiki repo to a temp directory:
```bash
WIKI_TMP=$(mktemp -d)
git clone https://github.com/alistairhendersoninfo/ninja_toolbox.wiki.git "$WIKI_TMP"
cd "$WIKI_TMP"
```

## Step 2: Make a trivial edit

Check if the argument is "spam" — if so, make a deliberately spammy edit to test detection. Otherwise make a clean edit.

### Clean edit (default):
Append a small timestamp comment to the bottom of `Home.md`:
```bash
echo "" >> Home.md
echo "<!-- Guardian test: $(date -u +%Y-%m-%dT%H:%M:%SZ) -->" >> Home.md
git add Home.md
git commit -m "test: wiki guardian health check"
```

### Spam edit (argument = "spam"):
Create a new page full of spam signals to verify the guardian catches it:
```bash
cat > Guardian-Test-Spam.md <<'EOF'
# Free Money Now!!!

CLICK HERE FOR FREE BITCOIN ETHEREUM CASINO GAMBLING
http://spam1.example.com http://spam2.example.com http://spam3.example.com
http://spam4.example.com http://spam5.example.com http://spam6.example.com
http://spam7.example.com http://spam8.example.com
BUY NOW FREE MONEY EARN MONEY CLICK HERE
BUY NOW FREE MONEY EARN MONEY CLICK HERE
BUY NOW FREE MONEY EARN MONEY CLICK HERE
EOF
git add Guardian-Test-Spam.md
git commit -m "test: spam detection verification"
```

## Step 3: Push to trigger the gollum event

```bash
git push origin master
```

## Step 4: Wait and check the action

Wait 10 seconds then check the latest Wiki Guardian run:
```bash
sleep 10
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/alistairhenderson/Development/ninja_toolbox)"
gh run list --workflow=wiki-guardian.yml --limit 3
```

## Step 5: Check result

Get the latest run ID and check its status:
```bash
RUN_ID=$(gh run list --workflow=wiki-guardian.yml --limit 1 --json databaseId --jq '.[0].databaseId')
gh run view "$RUN_ID"
```

If the run is still in progress, wait and check again:
```bash
gh run watch "$RUN_ID"
```

## Step 6: Report

Print a summary:
- Whether the run succeeded or failed
- If spam mode was used, whether the guardian detected and reverted it
- The run URL for manual inspection

## Step 7: Cleanup

Remove the temp directory:
```bash
rm -rf "$WIKI_TMP"
```

If spam mode was used and the guardian did NOT revert it, manually clean up:
```bash
cd "$WIKI_TMP" # re-clone if needed
git clone https://github.com/alistairhendersoninfo/ninja_toolbox.wiki.git /tmp/wiki-cleanup
cd /tmp/wiki-cleanup
git rm Guardian-Test-Spam.md
git commit -m "cleanup: remove guardian test spam page"
git push
rm -rf /tmp/wiki-cleanup
```
