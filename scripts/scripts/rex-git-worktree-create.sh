#!/bin/bash
# Find or create a git worktree (see git-worktree-ensure.sh), then open a Rex session
# with a shell in it and show that session in the Rex app.
#
# Session name: inside Rex, "<current-session>-<worktree-name>"; otherwise
# "<repo>-<worktree-name>". If a session with that name exists, it is reused.
WORKTREE_NAME=$1
BRANCH=${2:-$WORKTREE_NAME}
if [ -z "$WORKTREE_NAME" ]; then
  echo "Usage: rex-git-worktree-create.sh <worktree-name> [branch-name]"
  exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Use the rex CLI that Rex puts in every pane, else whatever is on PATH.
REX="${REX_BIN_DIR:+$REX_BIN_DIR/}rex"
if ! command -v "$REX" >/dev/null 2>&1; then
  echo "Error: the rex command was not found. Run this inside Rex or put rex on PATH."
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed."
  exit 1
fi

# Work out the session name before anything changes directory.
if [ -n "$REX_SESSION" ]; then
  CURRENT_SESSION=$("$REX" session inspect "$REX_SESSION" --json 2>/dev/null | jq -r '.label // empty')
fi
if [ -n "$CURRENT_SESSION" ]; then
  SESSION_NAME="$CURRENT_SESSION-$WORKTREE_NAME"
else
  # Get the repository name from remote origin URL
  REPONAME=$(git config --get remote.origin.url | sed 's/.*\/\([^ ]*\/[^.]*\).*/\1/' | sed 's/.*\///')
  SESSION_NAME="${REPONAME:-$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")}-$WORKTREE_NAME"
fi

echo "Creating worktree $WORKTREE_NAME"
WORKTREE_PATH=$("$SCRIPT_DIR/git-worktree-ensure.sh" "$WORKTREE_NAME" "$BRANCH") || exit 1

SESSION_ID=$("$REX" ls --json | jq -r --arg name "$SESSION_NAME" \
  'first(.sessions[] | select(.label == $name) | .session_id) // empty')
if [ -n "$SESSION_ID" ]; then
  echo "Session $SESSION_NAME already exists."
else
  echo "Creating session $SESSION_NAME"
  SESSION_ID=$("$REX" new "$SESSION_NAME" -c "$WORKTREE_PATH" --json | jq -r '.session_id // empty')
  if [ -z "$SESSION_ID" ]; then
    echo "Error: could not create Rex session $SESSION_NAME"
    exit 1
  fi
fi

echo "Switching to session $SESSION_NAME"
# Needs Remote Control turned on in Rex's settings, and one Rex app connected (or set
# REX_CLIENT). If it can't switch, the session still exists: pick it with cmd+k.
if ! "$REX" "do" session.select session_id="$SESSION_ID" >/dev/null; then
  echo "Could not switch the Rex app to $SESSION_NAME; choose it in the session picker (cmd+k)."
fi
