#!/usr/bin/env bash
set -euo pipefail

# Clone dotfiles and run bootstrap for GCP VM setup.
# Intended to be run as the SSH user (not root).

DOTFILES_DIR="$HOME/dotfiles"

if [[ -d "$DOTFILES_DIR" ]]; then
  echo "Dotfiles already cloned at $DOTFILES_DIR, pulling latest..."
  git -C "$DOTFILES_DIR" pull
else
  echo "Cloning dotfiles..."
  git clone https://github.com/zopu/dotfiles.git "$DOTFILES_DIR"
fi

echo "Running bootstrap..."
"$DOTFILES_DIR/scripts/bootstrap.sh"
