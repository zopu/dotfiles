# Homebrew Bundle — Full macOS dev environment
# Install with: brew bundle
#
# For remote/Linux environments, use Brewfile.core instead (cross-platform
# essentials only — no GUI apps, macOS-specific tools, or niche languages).
# bootstrap.sh selects the right file automatically based on OS.

# Taps
tap "browsh-org/browsh"
tap "clojure/tools"
tap "dart-lang/dart"
tap "epk/epk"
tap "FelixKratz/formulae"
tap "gromgit/brewtils"
tap "homebrew/services"
tap "jesseduffield/lazydocker"
tap "localstack/tap"
tap "nikitabobko/tap"
tap "oven-sh/bun"
tap "sst/tap"
tap "tako8ki/tap"
tap "twilio/brew"

# Core CLI tools
brew "act"
brew "ast-grep"       # Structural code search/lint/rewrite
brew "awscli"
brew "bat"            # Better cat with syntax highlighting
brew "bottom"         # Process/system monitor (btm)
brew "carapace"
brew "blueutil"       # Get/set Bluetooth power & state (Corne BLE keyboard)
brew "ccache"        # Compiler cache for faster rebuilds
brew "cfn-lint"
brew "clang-format"   # C/C++/JS/TS formatter
brew "claude-squad"
brew "cloudflared"
brew "cmake"
brew "coreutils"
brew "curl"
brew "deno"
brew "difftastic"
brew "direnv"
brew "docker"
brew "dolt"
brew "dtc"            # Device Tree Compiler
brew "dust"           # Better du (disk usage)
brew "editorconfig-checker"  # EditorConfig compliance
brew "eza"            # Better ls with colors and icons
brew "fd"
brew "ffmpeg"
brew "fzf"
brew "gh"            # GitHub CLI
brew "glow"           # Render markdown in the terminal
brew "git"
brew "git-delta"      # Better git diff viewer
brew "gitleaks"
brew "go"
brew "golangci-lint"
brew "gperf"          # Perfect hash function generator
brew "gopls"
brew "helix"
brew "htop"
brew "hyperfine"      # Benchmarking tool
brew "jnv"
brew "jq"
brew "just"           # Command runner (alternative to make)
brew "k6"
brew "kanata"
brew "ko"
brew "lazygit"
brew "libmagic"       # File type detection library
brew "libpq"
brew "mkcert"
brew "mold"
brew "mole"           # Deep clean & optimize macOS
brew "mysql"
brew "mysql-client"
brew "nasm"
brew "navi"
brew "neovim"
brew "ninja"          # Small build system
brew "nushell"        # Modern structured shell
brew "nvm"
brew "pipx"           # Python app isolation
brew "openocd"        # On-chip debugger
brew "pnpm"
brew "poetry"         # Python dependency management
brew "pre-commit"
brew "pulumi"         # Infrastructure as code
brew "python@3.10"
brew "python@3.11"
brew "python-tk@3.11" # Tkinter for Python
brew "qemu"
brew "railway"
brew "rclone"         # Rsync for cloud storage
brew "ripgrep"
brew "ruby"
brew "sbcl"
brew "selene"
brew "shellcheck"
brew "shfmt"
brew "spotify-tui"
brew "spr"
brew "sqlc"
brew "starship"
brew "stow"           # GNU Stow for dotfiles
brew "stylua"
brew "thefuck"
brew "tldr"           # Simplified man pages
brew "tmux"
brew "tmuxinator"     # Declarative tmux sessions
brew "tokei"          # Code statistics
brew "tpm"
brew "tree"           # Directory tree visualization
brew "tree-sitter"    # Incremental parsing library (Neovim)
brew "tree-sitter-cli" # Grammar generator/CLI
brew "wakeonlan"
brew "watchexec"
brew "websocat"
brew "wget"
brew "yamllint"       # YAML linting
brew "yazi"
brew "yq"             # YAML/JSON/XML processor
brew "z80asm"
brew "zellij"
brew "zig"
brew "zoxide"

# AI agent tooling
brew "beads"          # Memory upgrade for coding agents
brew "nono"           # Capability-based sandbox shell for AI agents

# Serial / embedded (pairs with openocd, qemu, dtc, nasm, z80asm)
brew "picocom"        # Minimal serial terminal

# Media
brew "kew"            # Command-line music player (pulls in audio libs)

# Specialized tap formulas
brew "browsh-org/browsh/browsh"
brew "clojure/tools/clojure"
brew "dart-lang/dart/dart"
brew "FelixKratz/formulae/borders"
brew "FelixKratz/formulae/sketchybar"
brew "jesseduffield/lazydocker/lazydocker"
brew "localstack/tap/localstack-cli"
brew "oven-sh/bun/bun"
brew "sst/tap/opencode"
brew "tako8ki/tap/gobang"
brew "twilio/brew/twilio"
brew "gromgit/brewtils/taproom"

# Additional runtimes & languages
brew "crystal"
brew "elixir"
brew "erlang"
brew "guile"
brew "leiningen"
brew "lua"
brew "opam"

# GUI apps & fonts
cask "1password-cli"  # 1Password CLI
cask "aerospace"      # Tiling window manager
cask "alacritty"      # Alternative terminal
cask "anaconda"       # Python distribution
cask "bluetility"     # Bluetooth GUI utility
cask "font-jetbrains-mono-nerd-font"
cask "font-sf-mono-nerd-font"
cask "font-hack-nerd-font"
cask "font-sketchybar-app-font"
cask "gcloud-cli"     # Google Cloud CLI
cask "mediosz/tap/swipeaerospace"
cask "rar"            # RAR archiver
cask "sf-symbols"     # Apple Symbols
cask "ghostty@tip"        # Terminal emulator
cask "machoview"      # Mach-O binary viewer
cask "temurin@17"     # Java 17 JDK
cask "tigervnc"       # VNC client
cask "wezterm"        # Terminal emulator
cask "xld"            # Audio converter

# Heavy / specialized (uncomment as needed on a given machine)
# cask "mactex"                          # LaTeX distribution (~5GB)
# cask "nordic-nrf-command-line-tools"   # nRF embedded debug tooling
# cask "segger-jlink"                    # Segger J-Link tools
# cask "pd"                              # Pure Data (audio programming)

# Post-install tips (not executed by Brewfile):
# - fzf: $(brew --prefix)/opt/fzf/install for key-bindings/completions
# - nvm: ensure NVM_DIR and lazy-load in zsh
# - direnv: echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc (guarded)
# - libpq: binaries at $(brew --prefix)/opt/libpq/bin
