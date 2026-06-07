export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR="nvim"
# EDITOR contains "vi", which makes zsh auto-select the viins keymap (^P/^N → self-insert).
bindkey -e

# Move tmux sockets out of /tmp on Linux to prevent systemd-tmpfiles cleanup
if [[ "$(uname)" == "Linux" ]]; then
  export TMUX_TMPDIR="$HOME/.tmux/sockets"
  mkdir -p "$TMUX_TMPDIR"
fi
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
  alias fuck='eval $(thefuck $(fc -ln -1))'
fi
alias prv="~/scripts/pi-review"
alias cpr="claude \"/pr-comment-auto\""
alias nv="nvim"
alias tgs="tm-git-worktree-session.sh"
alias tgo="tm-git-worktree-open.sh"
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

if command -v carapace >/dev/null 2>&1; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
  CARAPACE_CACHE="$HOME/.cache/carapace_cache.zsh"
  if [[ ! -f "$CARAPACE_CACHE" ]]; then
    mkdir -p "$(dirname "$CARAPACE_CACHE")"
    carapace _carapace > "$CARAPACE_CACHE" 2>/dev/null
  fi
  source "$CARAPACE_CACHE"
fi

function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

if [[ -o interactive ]]; then
    eval "$(zoxide init --cmd cd zsh)"
else
    eval "$(zoxide init zsh)"
fi

# Navi widget
eval "$(navi widget zsh)"

# Low-value frequent-use env credentials
[[ -f ~/.zshrc.secrets ]] && source ~/.zshrc.secrets
#compdef gt
###-begin-gt-completions-###
#
# yargs command completion script
#
# Installation: gt completion >> ~/.zshrc
#    or gt completion >> ~/.zprofile on OSX.
#
_gt_yargs_completions()
{
  local reply
  local si=$IFS
  IFS=$'
' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" gt --get-yargs-completions "${words[@]}"))
  IFS=$si
  _describe 'values' reply
}
compdef _gt_yargs_completions gt
###-end-gt-completions-###

