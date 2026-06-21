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

  # Set default shell to zsh
  if [[ "$(basename "$SHELL")" != "zsh" ]]; then
    ZSH_PATH="$(command -v zsh)"
    if ! grep -qx "$ZSH_PATH" /etc/shells; then
      info "Adding $ZSH_PATH to /etc/shells..."
      echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    info "Setting default shell to zsh..."
    sudo chsh -s "$ZSH_PATH" "$(whoami)"
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

# --- Homebrew health check --------------------------------------------------

# `brew doctor` exits non-zero on benign warnings, so it must never abort the
# run. Worth a look after a Migration Assistant / OS transfer, which can leave
# stale symlinks or arch-mismatched bottles behind. It only diagnoses — fixes
# (e.g. `brew cleanup`, `brew reinstall <formula>`) are left to you.
info "Running brew doctor (warnings here are often harmless)..."
brew doctor || warn "brew doctor reported issues; review the output above before relying on this install."

# --- Brew Bundle -------------------------------------------------------------

if [[ "$OS" == "Linux" ]]; then
  BREWFILE="$REPO_ROOT/Brewfile.core"
else
  BREWFILE="$REPO_ROOT/Brewfile"
fi

if [[ -f "$BREWFILE" ]]; then
  info "Updating Homebrew..."
  brew update
  # After a Migration Assistant transfer, upgrade everything so any deps/leaves
  # carried over from the old machine are refreshed (bundle only touches
  # Brewfile-listed packages). Non-fatal so a single failure doesn't abort.
  info "Upgrading installed formulae..."
  brew upgrade || warn "brew upgrade had failures; continuing."
  info "Running brew bundle with $(basename "$BREWFILE")..."
  brew bundle --file="$BREWFILE" || warn "brew bundle had failures; continuing with the rest of bootstrap."
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
    scripts
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
    scripts
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
  stow --dir="$REPO_ROOT" --target="$HOME" --restow "$pkg" \
    || warn "stow conflict on $pkg; resolve manually and re-run."
done

# --- Karabiner VirtualHIDDevice Daemon (macOS only) --------------------------

if [[ "$OS" != "Linux" ]]; then
  KARABINER_PLIST="org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist"
  KARABINER_LABEL="org.pqrs.Karabiner-VirtualHIDDevice-Daemon"
  KARABINER_SRC="$REPO_ROOT/kanata/$KARABINER_PLIST"
  KARABINER_DST="/Library/LaunchDaemons/$KARABINER_PLIST"

  if [[ ! -f "$KARABINER_SRC" ]]; then
    warn "Karabiner plist not found at $KARABINER_SRC. Skipping."
  else
    # Install the plist if missing.
    if [[ ! -f "$KARABINER_DST" ]]; then
      info "Installing Karabiner VirtualHIDDevice Daemon LaunchDaemon..."
      sudo cp "$KARABINER_SRC" "$KARABINER_DST"
    fi

    # Bootstrap the service only if it isn't already loaded in the system
    # domain. `bootstrap` is the modern replacement for the legacy `load`
    # subcommand (Sequoia+); guarding on `print` keeps this idempotent.
    if sudo launchctl print "system/$KARABINER_LABEL" >/dev/null 2>&1; then
      info "Karabiner VirtualHIDDevice Daemon already loaded."
    else
      info "Bootstrapping Karabiner VirtualHIDDevice Daemon..."
      sudo launchctl bootstrap system "$KARABINER_DST"
      success "Karabiner VirtualHIDDevice Daemon installed and loaded."
    fi
  fi
fi

# --- nrfutil (Nordic Semiconductor CLI, macOS only) --------------------------

if [[ "$OS" != "Linux" ]]; then
  NRFUTIL_DST="$HOME/bin/nrfutil"
  if [[ -x "$NRFUTIL_DST" ]]; then
    info "nrfutil already installed at $NRFUTIL_DST."
  else
    info "Installing nrfutil to $NRFUTIL_DST..."
    mkdir -p "$HOME/bin"
    if curl -fsSL -o "$NRFUTIL_DST" \
      "https://developer.nordicsemi.com/.pc-tools/nrfutil/universal-osx/nrfutil"; then
      chmod +x "$NRFUTIL_DST"
      success "nrfutil installed to $NRFUTIL_DST."
    else
      warn "Failed to download nrfutil. Skipping."
      rm -f "$NRFUTIL_DST"
    fi
  fi
fi

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
