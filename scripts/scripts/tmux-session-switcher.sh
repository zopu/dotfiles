#!/bin/bash
# Tmux session switcher using fzf
# Defaults to the most recently attached session (excluding current)

current_session=$(tmux display-message -p '#S')

# Get sessions sorted by last-attached time (most recent first), excluding current
selected=$(tmux ls -F '#{session_last_attached},#{session_name}' |
  sort -t, -rn |
  cut -d, -f2 |
  grep -v "^${current_session}$" |
  fzf --reverse --header "session" --no-sort)

if [ -n "$selected" ]; then
  tmux switch-client -t "$selected"
fi
