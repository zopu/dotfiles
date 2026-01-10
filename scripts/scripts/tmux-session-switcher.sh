#!/bin/bash
# Tmux session switcher using fzf
# Defaults to the most recently attached session (excluding current)

current_session=$(tmux display-message -p '#S')

# Get sessions sorted by last-attached time (most recent first), excluding current
selected=$(tmux ls -F '#{session_last_attached},#{session_name}' |
  sort -t, -rn |
  cut -d, -f2 |
  grep -v "^${current_session}$" |
  fzf --reverse --header "session (current: $current_session)" --no-sort \
    --preview 'dir=$(tmux display-message -t {}: -p "#{pane_current_path}"); echo "${dir/#$HOME/~}"; echo "---"; git -C "$dir" -c color.status=always status -sb 2>/dev/null || echo "(not a git repo)"' --preview-window=right:70%)

if [ -n "$selected" ]; then
  tmux switch-client -t "$selected"
fi
