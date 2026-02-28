#!/usr/bin/env bash
set -euo pipefail

# Bootstrap dev environment: Homebrew/Linuxbrew + Brewfile + GNU Stow
# Works on both macOS and Linux.

# Resolve repo root (script is expected at repo_root/scripts/bootstrap.sh)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

info() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
success() { printf "\033[1;32m[DONE]\033[0m %s\n" "$*"; }

OS="$(uname -s)"

# --- Homebrew / Linuxbrew ---------------------------------------------------

if [[ "$OS" == "Linux" ]]; then
  # Install zsh via apt before anything else (needed for stow target)
  if ! command -v zsh >/dev/null 2>&1; then
    info "Installing zsh via apt..."
    sudo apt-get update -qq && sudo apt-get install -y -qq zsh
  fi

  # Install Linuxbrew
  if ! command -v brew >/dev/null 2>&1; then
    info "Installing Linuxbrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Add brew to PATH for this script (full shellenv deferred until after stow)
  if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$('/home/linuxbrew/.linuxbrew/bin/brew' shellenv)"
  fi
else
  # macOS
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
fi

# --- Brew Bundle -------------------------------------------------------------

if [[ "$OS" == "Linux" ]]; then
  BREWFILE="$REPO_ROOT/Brewfile.core"
else
  BREWFILE="$REPO_ROOT/Brewfile"
fi

if [[ -f "$BREWFILE" ]]; then
  info "Updating Homebrew..."
  brew update
  info "Running brew bundle with $(basename "$BREWFILE")..."
  brew bundle --file="$BREWFILE"
else
  warn "No Brewfile at $BREWFILE. Skipping brew bundle."
fi

# --- GNU Stow ---------------------------------------------------------------

if ! command -v stow >/dev/null 2>&1; then
  info "Installing stow..."
  brew install stow
fi

# Platform-specific stow packages
if [[ "$OS" == "Linux" ]]; then
  PACKAGES=(
    nvim
    zsh
    tmux
    starship
    opencode
  )
else
  PACKAGES=(
    nvim
    zsh
    tmux
    wezterm
    starship
    ghostty
    kanata
    conda
    opencode
  )
fi

# Back up existing .zshrc if it's a real file (not a symlink)
if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
  cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
  info "Copied existing ~/.zshrc to ~/.zshrc.bak"
  rm "$HOME/.zshrc"
fi

for pkg in "${PACKAGES[@]}"; do
  if [[ ! -d "$REPO_ROOT/$pkg" ]]; then
    warn "Skipping $pkg (directory not found)"
    continue
  fi

  info "Stowing $pkg -> $HOME"
  stow --dir="$REPO_ROOT" --target="$HOME" --restow "$pkg"
done

# --- Linuxbrew shellenv (after stow so .zshrc is linked) ---------------------

if [[ "$OS" == "Linux" && -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  info "Sourcing Linuxbrew shellenv (post-stow)..."
  eval "$('/home/linuxbrew/.linuxbrew/bin/brew' shellenv)"
fi

# --- Post-install tips -------------------------------------------------------

if command -v fzf >/dev/null 2>&1; then
  FZF_INSTALL="$(brew --prefix)/opt/fzf/install"
  if [[ -x "$FZF_INSTALL" ]]; then
    info "Tip: enable fzf key-bindings/completions with: $FZF_INSTALL --key-bindings --completion --no-update-rc"
  fi
fi

success "Bootstrap complete. Open a new shell to pick up changes."
