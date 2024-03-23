export XDG_CONFIG_HOME="$HOME/.config"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="/opt/homebrew/opt/python@3.11/libexec/bin:$PATH"
export PATH="/Users/mikeperrow/zig:$PATH"
export PATH="/Users/mikeperrow/bin:$PATH"

alias nv="env TERM=wezterm nvim"
alias adv="cargo run --release --"
alias tgs="tm-git-worktree-session.sh"

# opam configuration
[[ ! -r /Users/mikeperrow/.opam/opam-init/init.zsh ]] || source /Users/mikeperrow/.opam/opam-init/init.zsh  > /dev/null 2> /dev/null

eval "$(starship init zsh)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# bun completions
[ -s "/Users/mikeperrow/.bun/_bun" ] && source "/Users/mikeperrow/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/scripts:$PATH"

# Created by `pipx` on 2024-03-06 17:18:01
export PATH="$PATH:/Users/mikeperrow/.local/bin"
