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

# Get the repository name from remote origin URL
REPONAME=$(git config --get remote.origin.url | sed 's/.*\/\([^ ]*\/[^.]*\).*/\1/' | sed 's/.*\///')

# Check if the repository is bare
if [ ! "$(git rev-parse --is-bare-repository)" = "true" ]; then
	# Check the parent dir
	cd ..
	if ! git rev-parse --is-inside-git-dir >/dev/null 2>&1; then
		echo "Error: This script must be run from within a Git repository."
		exit 1
	fi
fi

# Create session name format
SESSION_NAME="$REPONAME-$BRANCH"

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
if tmux list-sessions | grep -q "^$SESSION_NAME:"; then
	echo "Session $SESSION_NAME already exists."
else
	echo "Creating session $SESSION_NAME"
	tmux new-session -d -s $SESSION_NAME
	tmux new-window -t $SESSION_NAME:2 -n 'nv'
	tmux send-keys -t $SESSION_NAME:2 "nv ." C-m
	tmux new-window -t $SESSION_NAME:3 -n 'run'
fi

echo "Switching to session $SESSION_NAME"

# Switch to the session
if [ -n "$TMUX" ]; then
	tmux switch-client -t "$SESSION_NAME:2"
else
	# If not inside tmux, attach to the target session (or switch to it if already attached elsewhere)
	tmux attach-session -t "$SESSION_NAME:2" || tmux switch-client -t "$SESSION_NAME:2"
fi
