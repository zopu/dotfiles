#!/bin/bash
WORKTREE_NAME=$1
BRANCH=${2:-$WORKTREE_NAME}
if [ -z "$WORKTREE_NAME" ]; then
  echo "Usage: tm-git-worktree-session.sh <worktree-name> [branch-name]"
  exit 1
fi

# Check if the current directory is within a Git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1 && ! git rev-parse --is-inside-git-dir >/dev/null 2>&1; then
  echo "Error: This script must be run from within a Git repository."
  exit 1
fi

# Get the repository name from remote origin URL
REPONAME=$(git config --get remote.origin.url | sed 's/.*\/\([^ ]*\/[^.]*\).*/\1/' | sed 's/.*\///')

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

# Create session name format
# If inside tmux, base the new session name on the current session name
if [ -n "$TMUX" ]; then
  CURRENT_SESSION=$(tmux display-message -p '#S')
  SESSION_NAME="$CURRENT_SESSION-$WORKTREE_NAME"
else
  SESSION_NAME="$REPONAME-$WORKTREE_NAME"
fi

echo "Creating worktree $WORKTREE_NAME"

if [ -d "$WORKTREE_PATH" ]; then
  echo "Worktree already exists at $WORKTREE_PATH"
else
  echo "Worktree does not exist. Pulling and creating..."

  # Pull latest changes from main branch
  cd "$MAIN_PATH"
  git pull

  if [ "$IS_BARE" = "true" ]; then
    cd "$BARE_ROOT"
  else
    # Ensure the worktree base directory exists
    mkdir -p "$WORKTREE_BASE"
  fi

  git worktree add -b "$BRANCH" "$WORKTREE_PATH" main

  # Symlink Claude local settings from main repo to new worktree
  if [ -f "$MAIN_PATH/.claude/settings.local.json" ]; then
    echo "Symlinking Claude local settings..."
    mkdir -p "$WORKTREE_PATH/.claude"
    ln -s "$MAIN_PATH/.claude/settings.local.json" "$WORKTREE_PATH/.claude/settings.local.json"
  fi

  # Symlink AGENTS.local.md from main repo to new worktree
  if [ -f "$MAIN_PATH/AGENTS.local.md" ]; then
    echo "Symlinking AGENTS.local.md..."
    ln -s "$MAIN_PATH/AGENTS.local.md" "$WORKTREE_PATH/AGENTS.local.md"
  fi
fi

cd "$WORKTREE_PATH"

# Now start a tmux session
if tmux list-sessions | grep -q "^$SESSION_NAME:"; then
  echo "Session $SESSION_NAME already exists."
else
  echo "Creating session $SESSION_NAME"
  tmux new-session -d -s $SESSION_NAME
  tmux new-window -t $SESSION_NAME:2 -n 'nv'
  tmux send-keys -t $SESSION_NAME:2 "nv ." C-m
  tmux new-window -t $SESSION_NAME:3 -n 'claude'
  tmux send-keys -t $SESSION_NAME:3 "claude" C-m
  tmux new-window -t $SESSION_NAME:4 -n 'run'
fi

echo "Switching to session $SESSION_NAME"

# Switch to the session
if [ -n "$TMUX" ]; then
  tmux switch-client -t "$SESSION_NAME:2"
else
  # If not inside tmux, attach to the target session (or switch to it if already attached elsewhere)
  tmux attach-session -t "$SESSION_NAME:2" || tmux switch-client -t "$SESSION_NAME:2"
fi
