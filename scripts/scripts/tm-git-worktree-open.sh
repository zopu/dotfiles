#!/bin/bash
# Pick an existing worktree with fzf and open its tmux session.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

wt_name=$("$SCRIPT_DIR/git-worktree-pick.sh") || exit 1
if [ -z "$wt_name" ]; then
  exit 0
fi

exec "$SCRIPT_DIR/tm-git-worktree-session.sh" "$wt_name"
