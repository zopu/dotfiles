#!/bin/bash

# Check if the current directory is within a Git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1 && ! git rev-parse --is-inside-git-dir >/dev/null 2>&1; then
  echo "Error: This script must be run from within a Git repository."
  exit 1
fi

# Check if fzf is installed
if ! command -v fzf >/dev/null 2>&1; then
  echo "Error: fzf is required but not installed."
  exit 1
fi

# Parse git worktree list --porcelain to extract worktree names, branches, and paths
worktrees=()
while IFS= read -r line; do
  if [[ "$line" =~ ^worktree\ (.+) ]]; then
    wt_path="${BASH_REMATCH[1]}"
    wt_name=$(basename "$wt_path")
    wt_branch=""
  elif [[ "$line" =~ ^branch\ refs/heads/(.+) ]]; then
    wt_branch="${BASH_REMATCH[1]}"
  elif [[ -z "$line" && -n "$wt_path" ]]; then
    # End of entry (blank line separator) — filter out main/master by directory name
    if [[ "$wt_name" != "main" && "$wt_name" != "master" && -n "$wt_branch" ]]; then
      worktrees+=("$wt_name	$wt_branch	$wt_path")
    fi
    wt_path=""
    wt_branch=""
  fi
done < <(git worktree list --porcelain; echo)

if [ ${#worktrees[@]} -eq 0 ]; then
  echo "No worktrees found (excluding main/master)."
  exit 0
fi

# Present worktrees in fzf: show "worktree-name (branch)" with path in preview
selected=$(printf '%s\n' "${worktrees[@]}" | \
  awk -F'\t' '{ if ($1 == $2) print $1 "\t" $3; else print $1 " (" $2 ")\t" $3 }' | \
  fzf \
    --prompt="Select worktree: " \
    --delimiter='\t' \
    --with-nth=1 \
    --preview='echo {} | cut -f2 | xargs -I{} sh -c "echo \"Path: {}\"; echo; git -C {} status -sb 2>/dev/null"' \
    --preview-window=right:50%)

if [ -z "$selected" ]; then
  exit 0
fi

# Extract worktree name (first field, strip any " (branch)" suffix)
wt_name=$(echo "$selected" | cut -f1 | sed 's/ (.*//')

exec tm-git-worktree-session.sh "$wt_name"
