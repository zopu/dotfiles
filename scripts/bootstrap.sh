#!/usr/bin/env bash
set -euo pipefail

# Bootstrap macOS dev environment: Homebrew + Brewfile + GNU Stow

# Resolve repo root (script is expected at repo_root/scripts/bootstrap.sh)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

info() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
success() { printf "\033[1;32m[DONE]\033[0m %s\n" "$*"; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  warn "This script targets macOS. Continuing anyway."
fi

# Ensure Homebrew is installed
if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$('/opt/homebrew/bin/brew' shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$('/usr/local/bin/brew' shellenv)"
  fi
else
  info "Homebrew found: $(brew --version | head -n1)"
fi

# Install from Brewfile
if [[ -f "$REPO_ROOT/Brewfile" ]]; then
  info "Running brew bundle..."
  brew bundle --file="$REPO_ROOT/Brewfile"
else
  warn "No Brewfile at $REPO_ROOT/Brewfile. Skipping brew bundle."
fi

# Ensure GNU Stow is available
if ! command -v stow >/dev/null 2>&1; then
  info "Installing stow..."
  brew install stow
fi

# Stow selected packages
PACKAGES=(
  nvim
  zsh
  tmux
  wezterm
  starship
  ghostty
  kanata
  conda
)

for pkg in "${PACKAGES[@]}"; do
  if [[ ! -d "$REPO_ROOT/$pkg" ]]; then
    warn "Skipping $pkg (directory not found)"
    continue
  fi

  # No special cases; rely on GNU Stow for all packages

  info "Stowing $pkg -> $HOME"
  stow --dir="$REPO_ROOT" --target="$HOME" --restow "$pkg"
done

# Optional: suggest fzf key-bindings/completions installation without modifying rc files
if command -v fzf >/dev/null 2>&1 && [[ -x "$(brew --prefix)/opt/fzf/install" ]]; then
  info "Tip: enable fzf key-bindings/completions with: $(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc"
fi

success "Bootstrap complete. Open a new shell to pick up changes."
