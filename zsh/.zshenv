# ~/.zshenv: sourced for ALL zsh invocations (interactive, non-interactive, login).
# Use this for PATH setup that must be available everywhere, including tmux popups.

# Homebrew / Linuxbrew
if [ -d /opt/homebrew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
