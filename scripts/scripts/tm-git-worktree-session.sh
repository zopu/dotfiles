#!/bin/bash
BRANCH=$1
if [ -z "$BRANCH" ]; then
	echo "Usage: tm-git-worktree-session.sh <branch>"
	exit 1
fi

# Check if the current directory is within a Git repository
if ! git rev-parse --is-inside-git-dir >/dev/null 2>&1; then
	echo "Error: This script must be run from within a Git repository."
	exit 1
fi

# Check if the repository is bare
if [ ! "$(git rev-parse --is-bare-repository)" = "true" ]; then
	# Check the parent dir
	cd ..
	if ! git rev-parse --is-inside-git-dir >/dev/null 2>&1; then
		echo "Error: This script must be run from within a Git repository."
		exit 1
	fi
fi

echo "creating worktree $BRANCH"
#
if [ -d "$BRANCH" ]; then
	echo "Worktree already exists"
else
	echo "Worktree does not exist. Pulling into main and creating"
	cd main
	git pull
	cd ..
	git worktree add $BRANCH
fi

cd $BRANCH

# Now start a tmux session
if tmux list-sessions | grep -q "^$BRANCH:"; then
	echo "Session $BRANCH already exists."
else
	echo "Creating session $BRANCH"
	tmux new-session -d -s $BRANCH
	tmux new-window -t $BRANCH:2 -n 'nv'
	tmux send-keys -t $BRANCH:2 "nv ." C-m
	tmux new-window -t $BRANCH:3 -n 'run'
fi

echo "Switching to session $BRANCH"

# Switch to the session
if [ -n "$TMUX" ]; then
	tmux switch-client -t "$BRANCH:2"
else
	# If not inside tmux, attach to the target session (or switch to it if already attached elsewhere)
	tmux attach-session -t "$BRANCH:2" || tmux switch-client -t "$BRANCH:2"
fi
