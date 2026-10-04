# ~/.zshenv: sourced for ALL zsh invocations (interactive, non-interactive, login).
# Use this for PATH setup that must be available everywhere, including tmux popups.

# Homebrew / Linuxbrew
if [ -d /opt/homebrew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Rust (rustup)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Flutter SDK (cloned checkout)
[ -d "$HOME/code/flutter/flutter/bin" ] && export PATH="$HOME/code/flutter/flutter/bin:$PATH"
