# Commit changes and file a PR using Graphite

## Ensure any relevant checks before commit are done.

Follow any instructions in CLAUDE.md for:
- Running all tests
- Formatting code
- Linting

## Commit and file a PR
- Use the Graphite CLI (gt) for all interactions with git
- Determine current state:
  - `git status` - check for uncommitted changes
  - `gt log short` - check for commits on current branch (shows stack)
- Choose the right command based on state:
  - Uncommitted changes only: `gt create -m "message"` to create branch + commit
  - Already committed + uncommitted changes: `gt modify -m "message"` to amend
  - Already committed, no uncommitted changes: `gt modify -m "message"` to set PR title/description
- Use `gt submit` to create the PR
- Open the PR in Graphite in my web browser

Any specific requests: $ARGUMENTS
