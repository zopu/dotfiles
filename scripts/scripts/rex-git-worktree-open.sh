#!/bin/bash
# Pick an existing worktree with fzf and open (or create) its Rex session.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

wt_name=$("$SCRIPT_DIR/git-worktree-pick.sh") || exit 1
if [ -z "$wt_name" ]; then
  exit 0
fi

exec "$SCRIPT_DIR/rex-git-worktree-create.sh" "$wt_name"
