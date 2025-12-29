---
name: pr-response
description: Respond directly to individual PR review comments using the GitHub API. Use when asked to reply to PR comments, address reviewer feedback, or communicate with reviewers on a PR.
---

# PR Comment Response

Respond directly to individual review comments on a GitHub PR.

## Instructions

1. First, fetch the current PR's review comments to get the comment IDs:
   ```bash
   gh pr view --json number -q '.number'  # Get PR number
   gh api "repos/{owner}/{repo}/pulls/{pr_number}/comments" --jq '.[] | {id, path, body, user: .user.login}'
   ```

2. For each comment you need to respond to, use the script in this skill directory:
   ```bash
   ~/.claude/skills/pr-response/gh-reply-pr-comment.sh <comment_id> "<response_body>"
   ```

3. Always prefix your response with `[claude]` so reviewers know the response is from Claude.

4. Be concise, professional, and address the specific feedback in the comment.

## Example

If a reviewer comments "Why did you use a map here instead of a for loop?":

```bash
~/.claude/skills/pr-response/gh-reply-pr-comment.sh 1234567890 "[claude] The map was chosen for its declarative style and to avoid mutation of external state. Happy to refactor to a for loop if that's preferred for consistency with the codebase."
```

## When to use

- When asked to respond to PR review comments
- When asked to reply to feedback on a PR
- After addressing review feedback and wanting to notify the reviewer
