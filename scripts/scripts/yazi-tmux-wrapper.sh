#!/bin/zsh

# Yazi wrapper for tmux that persists directory after exit
# Based on the y() function from zshrc but modified for tmux sessions

local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
yazi "$@" --cwd-file="$tmp"
IFS= read -r -d '' cwd < "$tmp"

if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    cd "$cwd"
fi

rm -f -- "$tmp"

# Keep the shell running in the selected directory
exec zsh