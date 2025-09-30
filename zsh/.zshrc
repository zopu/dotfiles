export XDG_CONFIG_HOME="$HOME/.config"
export NVM_DIR="$HOME/.nvm"
# Lazy load nvm for faster shell startup
nvm() {
    unset -f nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm "$@"
}

# Make default node available immediately while keeping lazy loading benefits
if [ -s "$NVM_DIR/nvm.sh" ] && [ -d "$NVM_DIR/versions/node" ]; then
    # Find the latest installed node version
    LATEST_NODE=$(ls -1 "$NVM_DIR/versions/node" | sort -V | tail -n 1)
    if [ -n "$LATEST_NODE" ] && [ -d "$NVM_DIR/versions/node/$LATEST_NODE" ]; then
        export PATH="$NVM_DIR/versions/node/$LATEST_NODE/bin:$PATH"
    fi
fi

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="/opt/homebrew/opt/python@3.11/libexec/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Guard optional tools
if command -v thefuck >/dev/null 2>&1; then
  eval "$(thefuck --alias)"
fi
alias nv="env TERM=wezterm nvim"
alias tgs="tm-git-worktree-session.sh"
alias lg="lazygit"
alias lzd='lazydocker'
alias fk="fuck"
alias t="tmux a"

# opam configuration
[[ ! -r $HOME/.opam/opam-init/init.zsh ]] || source $HOME/.opam/opam-init/init.zsh  > /dev/null 2> /dev/null

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/scripts:$PATH"

# Created by `pipx` on 2024-03-06 17:18:01
export PATH="$PATH:$HOME/.local/bin"
# export PATH="/opt/homebrew/anaconda3/bin:$PATH"  # commented out by conda initialize

# >>> conda initialize >>>
# Lazy load conda for faster shell startup
conda() {
    unset -f conda
    __conda_setup="$('/opt/homebrew/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/opt/homebrew/anaconda3/etc/profile.d/conda.sh" ]; then
            . "/opt/homebrew/anaconda3/etc/profile.d/conda.sh"
        else
            export PATH="/opt/homebrew/anaconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
    # Prefer setting changeps1: false in ~/.condarc to avoid per-shell config calls
    conda "$@"
}
# <<< conda initialize <<<

alias claude="$HOME/.claude/local/claude"

export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
source <(carapace _carapace)

function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

eval "$(zoxide init --cmd cd zsh)"
