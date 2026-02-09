#!/bin/bash
# Wiki Guardian - Automated spam detection for GitHub wiki edits
# Triggered by the gollum event via .github/workflows/wiki-guardian.yml
#
# Checks the latest wiki commit diff for spam signals and outputs
# spam=true/false for the workflow to act on.

set -euo pipefail

WIKI_DIR="${1:?Usage: wiki-guardian.sh <wiki-directory>}"
SPAM_THRESHOLD=3
spam_score=0
reasons=()

cd "$WIKI_DIR"

# Get the latest commit info
COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_AUTHOR=$(git log -1 --format='%an <%ae>')
COMMIT_MSG=$(git log -1 --format='%s')
CHANGED_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null || echo "")

# If this is the initial commit or there's no parent, skip
if ! git rev-parse HEAD~1 >/dev/null 2>&1; then
    echo "Initial commit -- skipping scan"
    echo "spam=false" >> "$GITHUB_OUTPUT"
    exit 0
fi

# Get the diff
DIFF=$(git diff HEAD~1 HEAD -- '*.md' 2>/dev/null || echo "")
ADDED_LINES=$(echo "$DIFF" | grep '^+[^+]' || true)

if [ -z "$ADDED_LINES" ]; then
    echo "No added content -- skipping scan"
    echo "spam=false" >> "$GITHUB_OUTPUT"
    exit 0
fi

echo "Scanning wiki edit by: $COMMIT_AUTHOR"
echo "Changed files: $CHANGED_FILES"
echo "---"

# --- Spam Signal 1: Excessive URLs ---
url_count=$(echo "$ADDED_LINES" | { grep -oiE 'https?://[^ )]+' || true; } | wc -l | tr -d ' ')
if [ "$url_count" -gt 5 ]; then
    spam_score=$((spam_score + 2))
    reasons+=("Excessive URLs: $url_count links added in one edit")
    echo "SIGNAL: $url_count URLs found (threshold: 5)"
fi

# --- Spam Signal 2: Known spam domain patterns ---
spam_domains="(crypto|bitcoin|ethereum|casino|gambling|poker|slot|pharma|viagra|cialis|dating|singles|onlyfans|buy-now|free-money|earn-money|click-here|bit\.ly/[a-z0-9]{4,})"
spam_domain_hits=$(echo "$ADDED_LINES" | { grep -oiE "$spam_domains" || true; } | wc -l | tr -d ' ')
if [ "$spam_domain_hits" -gt 0 ]; then
    spam_score=$((spam_score + 3))
    reasons+=("Spam keywords detected: $spam_domain_hits matches for known spam patterns")
    echo "SIGNAL: $spam_domain_hits spam keyword matches"
fi

# --- Spam Signal 3: Large content deletion (vandalism) ---
deleted_lines=$(echo "$DIFF" | { grep '^-[^-]' || true; } | wc -l | tr -d ' ')
added_lines_count=$(echo "$ADDED_LINES" | wc -l | tr -d ' ')
if [ "$deleted_lines" -gt 20 ] && [ "$added_lines_count" -lt 5 ]; then
    spam_score=$((spam_score + 3))
    reasons+=("Possible vandalism: $deleted_lines lines deleted, only $added_lines_count lines added")
    echo "SIGNAL: Large deletion ($deleted_lines removed, $added_lines_count added)"
fi

# --- Spam Signal 4: Repeated text patterns ---
if [ "$added_lines_count" -gt 3 ]; then
    unique_lines=$(echo "$ADDED_LINES" | sort -u | wc -l | tr -d ' ')
    repeat_ratio=$(( (added_lines_count - unique_lines) * 100 / added_lines_count ))
    if [ "$repeat_ratio" -gt 60 ]; then
        spam_score=$((spam_score + 2))
        reasons+=("Repetitive content: ${repeat_ratio}% of added lines are duplicates")
        echo "SIGNAL: ${repeat_ratio}% repeated content"
    fi
fi

# --- Spam Signal 5: New page with mostly links, little prose ---
for file in $CHANGED_FILES; do
    if ! git show HEAD~1:"$file" >/dev/null 2>&1; then
        # This is a new page
        file_content=$(git show HEAD:"$file" 2>/dev/null || true)
        total_lines=$(echo "$file_content" | wc -l | tr -d ' ')
        link_lines=$(echo "$file_content" | grep -cE 'https?://' || true)
        if [ "$total_lines" -gt 0 ] && [ "$link_lines" -gt 0 ]; then
            link_ratio=$(( link_lines * 100 / total_lines ))
            if [ "$link_ratio" -gt 50 ] && [ "$total_lines" -gt 3 ]; then
                spam_score=$((spam_score + 2))
                reasons+=("New page '$file' is ${link_ratio}% links ($link_lines/$total_lines lines)")
                echo "SIGNAL: New link-heavy page: $file"
            fi
        fi
    fi
done

# --- Spam Signal 6: All-caps or gibberish ---
allcaps_lines=$(echo "$ADDED_LINES" | grep -cE '^[+][A-Z !@#$%^&*]{20,}$' || true)
if [ "$allcaps_lines" -gt 2 ]; then
    spam_score=$((spam_score + 2))
    reasons+=("All-caps/gibberish: $allcaps_lines lines of all-caps text")
    echo "SIGNAL: $allcaps_lines all-caps lines"
fi

echo "---"
echo "Spam score: $spam_score (threshold: $SPAM_THRESHOLD)"

# --- Generate report ---
report_file="/tmp/wiki-guardian-report.md"
cat > "$report_file" <<EOF
## Wiki Guardian Report

**Commit:** \`$COMMIT_HASH\`
**Author:** $COMMIT_AUTHOR
**Message:** $COMMIT_MSG
**Changed files:** $CHANGED_FILES
**Spam score:** $spam_score / $SPAM_THRESHOLD threshold

### Detection Signals

EOF

if [ ${#reasons[@]} -eq 0 ]; then
    echo "No spam signals detected." >> "$report_file"
else
    for reason in "${reasons[@]}"; do
        echo "- $reason" >> "$report_file"
    done
fi

cat >> "$report_file" <<EOF

### Action Taken

EOF

if [ "$spam_score" -ge "$SPAM_THRESHOLD" ]; then
    echo "The edit has been **automatically reverted**. Review the signals above and restore the edit if it was a false positive." >> "$report_file"
    echo "spam=true" >> "$GITHUB_OUTPUT"
    echo "RESULT: SPAM DETECTED -- will revert"
else
    echo "No action taken. Edit appears clean." >> "$report_file"
    echo "spam=false" >> "$GITHUB_OUTPUT"
    echo "RESULT: Clean"
fi
