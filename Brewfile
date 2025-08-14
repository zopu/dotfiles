# Homebrew Bundle for macOS dev environment
# Install with: brew bundle

# Taps (only non-default)
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
brew "bat"            # Better cat with syntax highlighting
brew "eza"            # Better ls with colors and icons
brew "tree"           # Directory tree visualization
brew "curl"
brew "wget"
brew "git-delta"      # Better git diff viewer

# Runtimes & languages (aligned with zsh config)
brew "python@3.11"
brew "python@3.12"
brew "go"
brew "nvm"
brew "oven-sh/bun/bun"
brew "libpq"
brew "deno"           # JavaScript/TypeScript runtime
brew "node@18"        # Specific Node.js version
brew "poetry"         # Python dependency management
brew "pipx"           # Python app isolation

# Editor/tooling integrations
brew "sqlite"         # for nvim sqlite-backed plugins
brew "lazygit"
brew "lazydocker"
brew "docker"         # Container platform
brew "just"           # Command runner (alternative to make)
brew "hyperfine"      # Benchmarking tool
brew "tokei"          # Code statistics
brew "dust"           # Better du (disk usage)
brew "tldr"           # Simplified man pages

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
brew "yamllint"       # YAML linting
brew "editorconfig-checker"  # EditorConfig compliance

# GUI apps & fonts
cask "wezterm"
cask "ghostty"
cask "alacritty"      # Alternative terminal
cask "font-jetbrains-mono-nerd-font"
cask "font-sf-mono-nerd-font"
cask "1password-cli"  # 1Password CLI
cask "temurin17"      # Java 17 JDK
 
# Post-install tips (not executed by Brewfile):
# - fzf: $(brew --prefix)/opt/fzf/install for key-bindings/completions
# - nvm: ensure NVM_DIR and lazy-load in zsh
# - direnv: echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc (guarded)
# - libpq: binaries at $(brew --prefix)/opt/libpq/bin
