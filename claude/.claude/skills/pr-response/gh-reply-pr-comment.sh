#!/bin/bash
# Reply to a PR review comment using the GitHub API
# Usage: gh-reply-pr-comment.sh <comment_id> <body>
#
# Arguments:
#   comment_id: The ID of the review comment to reply to
#   body: The text of the reply
#
# The script automatically detects the repo and PR number from the current directory.

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: gh-reply-pr-comment.sh <comment_id> <body>" >&2
    exit 1
fi

COMMENT_ID="$1"
BODY="$2"

# Get the repo in owner/name format
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')

if [[ -z "$REPO" ]]; then
    echo "Error: Could not determine repository. Make sure you're in a git repo." >&2
    exit 1
fi

# Get the current branch
BRANCH=$(git branch --show-current)

# Try to find PR number for this branch
PR_NUMBER=$(gh pr view "$BRANCH" --json number -q '.number' 2>/dev/null || true)

if [[ -z "$PR_NUMBER" ]]; then
    echo "Error: Could not find a PR for branch '$BRANCH'." >&2
    echo "Make sure there's an open PR for this branch." >&2
    exit 1
fi

# Reply to the comment using gh api
gh api \
    --method POST \
    "repos/${REPO}/pulls/${PR_NUMBER}/comments/${COMMENT_ID}/replies" \
    -f body="$BODY"

echo "Successfully replied to comment $COMMENT_ID on PR #$PR_NUMBER"
