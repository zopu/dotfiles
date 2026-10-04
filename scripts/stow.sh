#!/usr/bin/env bash
set -euo pipefail

# Idempotently (re)stow dotfiles packages into $HOME. Safe to re-run after
# changing the package layout.
#
# Usage: stow.sh [-n|--dry-run] [package...]
#   With no packages, stows the platform default list below.

# Resolve repo root (script is expected at repo_root/scripts/stow.sh)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

info() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }

OS="$(uname -s)"
DRY_RUN=0
ARGS=()
for arg in "$@"; do
  case "$arg" in
    -n | --dry-run) DRY_RUN=1 ;;
    *) ARGS+=("$arg") ;;
  esac
done

if ! command -v stow >/dev/null 2>&1; then
  info "Installing stow..."
  brew install stow
fi

# Platform-specific stow packages
# Keep these lists in sync with the package directories at the repo root.
# Deliberately NOT stowed: nas (repo-local rclone scripts, run in place) and
# plans (repo notes, not config).
if [[ "$OS" == "Linux" ]]; then
  PACKAGES=(
    claude
    navi
    nushell
    nvim
    opencode
    scripts
    starship
    tmux
    yazi
    zsh
  )
else
  PACKAGES=(
    aerospace
    claude
    conda
    ghostty
    kanata
    launchagents
    navi
    nushell
    nvim
    opencode
    scripts
    sketchybar
    starship
    tmux
    wezterm
    yazi
    zsh
  )
fi
if [[ ${#ARGS[@]} -gt 0 ]]; then
  PACKAGES=("${ARGS[@]}")
fi

# Directories (relative to $HOME) that must be real directories rather than
# one folded symlink into the repo. Other tools install into these (Claude
# Code's synced skills, `npx skills add`), and a folded symlink would make
# them write straight into the repo. Stow never folds into an existing real
# directory, so it links each repo entry individually instead.
UNFOLD_DIRS=(
  .claude/skills
)

for dir in "${UNFOLD_DIRS[@]}"; do
  path="$HOME/$dir"
  if [[ -L "$path" ]]; then
    target="$(cd "$path" 2>/dev/null && pwd -P || true)"
    if [[ "$target" != "$REPO_ROOT"/* ]]; then
      warn "$path is a symlink outside the repo ($target); leaving it alone."
      continue
    fi
    info "Unfolding $path (was a symlink into the repo)"
    [[ $DRY_RUN -eq 1 ]] || rm "$path"
  fi
  if [[ ! -d "$path" ]]; then
    [[ $DRY_RUN -eq 1 ]] || mkdir -p "$path"
  fi
done

# Back up existing .zshrc if it's a real file (not a symlink)
if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" && $DRY_RUN -eq 0 ]]; then
  cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
  info "Copied existing ~/.zshrc to ~/.zshrc.bak"
  rm "$HOME/.zshrc"
fi

STOW_FLAGS=(--dir="$REPO_ROOT" --target="$HOME" --restow --ignore='\.DS_Store')
[[ $DRY_RUN -eq 1 ]] && STOW_FLAGS+=(--no --verbose=1)

for pkg in "${PACKAGES[@]}"; do
  if [[ ! -d "$REPO_ROOT/$pkg" ]]; then
    warn "Skipping $pkg (directory not found)"
    continue
  fi

  # --ignore keeps Finder droppings from being stowed into $HOME (a stray
  # package-root .DS_Store otherwise collides with ~/.DS_Store and, because
  # stow aborts a package on its first conflict, silently blocks every other
  # file in that package.
  info "Stowing $pkg -> $HOME"
  stow "${STOW_FLAGS[@]}" "$pkg" \
    || warn "stow conflict on $pkg; resolve manually and re-run."
done
