#!/bin/sh
# Called from tmux display-popup to prompt for input,
# then opens a new tmux window running claude with that prompt.
printf "Claude prompt: "
read -r p
[ -z "$p" ] && exit 1
printf '%s' "$p" > /tmp/claude-quick-prompt
tmux new-window -n claude -c "$1" 'sh -c "exec claude --model haiku \"$(cat /tmp/claude-quick-prompt)\""'
