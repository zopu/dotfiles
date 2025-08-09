# Homebrew Bundle for macOS dev environment
# Install with: brew bundle

# Taps
tap "homebrew/bundle"
tap "homebrew/cask"
tap "homebrew/cask-fonts"
tap "oven-sh/bun"

# Core CLI
brew "git"
brew "stow"           # GNU Stow for dotfiles
brew "neovim"
brew "tmux"
brew "ripgrep"
brew "fd"
brew "fzf"
brew "gh"            # GitHub CLI
brew "jq"

# Runtimes & languages (aligned with zsh config)
brew "python@3.11"
brew "go"
brew "nvm"
brew "bun"
brew "libpq"

# Editor/tooling integrations
brew "sqlite"         # for nvim sqlite-backed plugins
brew "lazygit"
brew "lazydocker"

# Shell UX & env tools
brew "starship"
brew "direnv"
brew "zoxide"
brew "thefuck"

# Linting/formatting & safety
brew "pre-commit"
brew "shellcheck"
brew "shfmt"
brew "stylua"
brew "selene"
brew "gitleaks"

# GUI apps & fonts
cask "wezterm"
cask "ghostty"
cask "font-jetbrains-mono-nerd-font"
 
# Post-install tips (not executed by Brewfile):
# - fzf: $(brew --prefix)/opt/fzf/install for key-bindings/completions
# - nvm: ensure NVM_DIR and lazy-load in zsh
# - direnv: echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc (guarded)
# - libpq: binaries at $(brew --prefix)/opt/libpq/bin
