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

# Create session name format
# If inside tmux, base the new session name on the current session name
if [ -n "$TMUX" ]; then
  CURRENT_SESSION=$(tmux display-message -p '#S')
  SESSION_NAME="$CURRENT_SESSION-$WORKTREE_NAME"
else
  SESSION_NAME="$REPONAME-$WORKTREE_NAME"
fi

echo "Creating worktree $WORKTREE_NAME"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WORKTREE_PATH=$("$SCRIPT_DIR/git-worktree-ensure.sh" "$WORKTREE_NAME" "$BRANCH") || exit 1

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
