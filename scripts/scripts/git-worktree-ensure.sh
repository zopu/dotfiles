#!/bin/bash
# Find or create a git worktree, and print its absolute path on stdout.
# Progress messages and git's own output go to stderr, so callers can do:
#   wt=$(git-worktree-ensure.sh <worktree-name> [branch-name]) || exit 1
#
# Location:
#   bare repo (run from its root): <bare-root>/<worktree-name>, branched from main
#   non-bare repo: <repo-parent>/<repo>-wt/<worktree-name>, branched from main
# A new worktree gets symlinks to the main checkout's .claude/settings.local.json
# and AGENTS.local.md, when those exist.

WORKTREE_NAME=$1
BRANCH=${2:-$WORKTREE_NAME}
if [ -z "$WORKTREE_NAME" ]; then
  echo "Usage: git-worktree-ensure.sh <worktree-name> [branch-name]" >&2
  exit 1
fi

# Check if the current directory is within a Git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1 && ! git rev-parse --is-inside-git-dir >/dev/null 2>&1; then
  echo "Error: This script must be run from within a Git repository." >&2
  exit 1
fi

# Check if the repository is bare
IS_BARE=$(git rev-parse --is-bare-repository)

if [ "$IS_BARE" = "true" ]; then
  # Bare repo: worktrees are subdirectories
  BARE_ROOT=$(pwd)
  WORKTREE_PATH="$BARE_ROOT/$WORKTREE_NAME"
  MAIN_PATH="$BARE_ROOT/main"
else
  # Non-bare repo: worktrees go in sibling <repo>-wt folder
  # Use --git-common-dir to find the main repo even when inside a worktree
  # Convert to absolute path since git may return relative ".git" in main repo
  GIT_COMMON_DIR=$(realpath "$(git rev-parse --git-common-dir)")
  MAIN_PATH=$(dirname "$GIT_COMMON_DIR")
  REPO_DIR=$(dirname "$MAIN_PATH")
  REPO_BASENAME=$(basename "$MAIN_PATH")
  WORKTREE_BASE="$REPO_DIR/${REPO_BASENAME}-wt"
  WORKTREE_PATH="$WORKTREE_BASE/$WORKTREE_NAME"
fi

if [ -d "$WORKTREE_PATH" ]; then
  echo "Worktree already exists at $WORKTREE_PATH" >&2
else
  echo "Worktree does not exist. Pulling and creating..." >&2

  # Pull latest changes from main branch
  cd "$MAIN_PATH" || exit 1
  git pull >&2

  if [ "$IS_BARE" = "true" ]; then
    cd "$BARE_ROOT" || exit 1
  else
    # Ensure the worktree base directory exists
    mkdir -p "$WORKTREE_BASE"
  fi

  if ! git worktree add -b "$BRANCH" "$WORKTREE_PATH" main >&2; then
    echo "Error: could not create worktree $WORKTREE_PATH" >&2
    exit 1
  fi

  # Symlink Claude local settings from main repo to new worktree
  if [ -f "$MAIN_PATH/.claude/settings.local.json" ]; then
    echo "Symlinking Claude local settings..." >&2
    mkdir -p "$WORKTREE_PATH/.claude"
    ln -s "$MAIN_PATH/.claude/settings.local.json" "$WORKTREE_PATH/.claude/settings.local.json"
  fi

  # Symlink AGENTS.local.md from main repo to new worktree
  if [ -f "$MAIN_PATH/AGENTS.local.md" ]; then
    echo "Symlinking AGENTS.local.md..." >&2
    ln -s "$MAIN_PATH/AGENTS.local.md" "$WORKTREE_PATH/AGENTS.local.md"
  fi
fi

echo "$WORKTREE_PATH"
