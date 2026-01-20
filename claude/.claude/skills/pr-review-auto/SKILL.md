---
name: pr-comment-auto
description: Wait for PR review comments, fix issues raised, summarise, and respond to reviewers automatically.
---

# PR Comment Handling

Perform the following steps:
- Find the PR for this branch.
- Wait for AI/Agent code reviews, from github copilot or graphite agent.
- Categorise comments into:
  - Minor issues (typos, formatting, small improvements)
  - Comments that should be ignored (not relevant, out of scope, subjective preferences, etc)
  - Major issues (bugs, design flaws, missing features), and anything requiring clarification.
  - Issues raised by a human reviewer.
- Deal with minor issues first before moving on to major issues.
- For minor issues, automatically make fixes in the codebase. Respond to the comments directly on the PR.
- For comments that should be ignored, respond directly on the PR explaining why they are being ignored.
- For major issues and clarification requests, generate a concise summary of the issues raised, make a recommendation, and prompt for a user review.
- At that user review, also include a summary of minor issues found and addressed and any changes made.
- After user approval, respond to major issues and clarification requests directly on the PR. Then address issues as instructed/approved.

## Waiting for code reviews

Check if an AI agent (copilot, graphite agent) has already left comments on the PR that have not been responded to.

If not, use the `wait_for_reviews.py` script in this skill's directory to poll for reviews:

```bash
python ~/.claude/skills/pr-review-auto/wait_for_reviews.py owner/repo PR_NUMBER --timeout 900 --interval 300
```

The script will:
- Poll the GitHub API every 5 minutes (300s) for up to 15 minutes (900s)
- Return JSON with `{"status": "found"|"timeout", "comments": [...], "reviews": [...]}`
- Print progress to stderr

## Fetching PR Comments

Please take care to fetch *all* comments on the PR, as github often truncates its responses.

## Responding to Review Comments

Use the pr-response skill to reply to individual PR comments via the GitHub API.

Clearly mark your response with the prefix "[claude]" so that it's clear who is responding.

## Making fixes

Always ensure that any relevant checks (e.g. formatting, linting, type checking, tests) are run after making changes.

## Watch Outs

- Do *not* commit changes or push code as part of this process, unless explicitly instructed to do so.
- Do *not* respond to comments from human reviewers without prior approval.
