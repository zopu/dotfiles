export XDG_CONFIG_HOME="$HOME/.config"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="/opt/homebrew/opt/python@3.11/libexec/bin:$PATH"
export PATH="/Users/mikeperrow/bin:$PATH"

eval $(thefuck --alias)
alias nv="env TERM=wezterm nvim"
alias tgs="tm-git-worktree-session.sh"
alias lg="lazygit"
alias lzd='lazydocker'
alias fk="fuck"

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
# export PATH="/opt/homebrew/anaconda3/bin:$PATH"  # commented out by conda initialize

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
/opt/homebrew/anaconda3/bin/conda config --set changeps1 False
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
# <<< conda initialize <<<

alias claude="/Users/mikeperrow/.claude/local/claude"
