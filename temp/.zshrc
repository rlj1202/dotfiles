################################################################################
# aliases
################################################################################

alias ls='ls -G'
alias lsa='ls -lah'
alias l='ls -lah'
alias ll='ls -lh'
alias la='ls -lAh'

################################################################################
# prompt
################################################################################

# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html

autoload -U colors && colors

setopt prompt_subst

function prompt_user_host() {
    echo -n "%B%(!.%{$fg[red]%}.%{$fg[green]%})%n@%m%{$reset_color%}"
}

function prompt_current_dir() {
    echo -n "%B%{$fg[blue]%}%~%{$reset_color%}"
}

function prompt_time() {
    echo -n "%D %*"
}

function prompt_vcs() {
    echo -n "git:("
    echo -n "%{$fg[yellow]%}"
    # FIXME:
    echo -n "$(echo not yet)"
    echo -n "%{$reset_color%}"
    echo -n ")"
}

function build_prompt() {
    local segments=(
        "$(prompt_user_host)"
        "$(prompt_current_dir)"
        "$(prompt_vcs)"
        "$(prompt_fnm)"
        "$(prompt_time)"
    )
    local user_symbol='%(!.#.$)'

    echo -n "%(?..%B%{$fg[red]%})╭─%b%{$reset_color%}"
    for segment in "${segments[@]}"; do
        [[ -n "$segment" ]] || continue
        echo -n "$segment "
    done
    echo ""
    echo "%(?..%B%{$fg[red]%})╰─%b%{$reset_color%}%B${user_symbol}%b "
}

function build_rprompt() {
    local return_code="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"

    echo "%B${return_code}%b"
}

PROMPT='$(build_prompt)'
RPROMPT='$(build_rprompt)'

################################################################################
# zsh-autosuggestions
################################################################################

# FIXME:
DOTFILES=~/dev/dotfiles
source $DOTFILES/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

################################################################################
# zsh-syntax-highlighting
################################################################################

source $DOTFILES/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

################################################################################
# proto
################################################################################

export PROTO_HOME="$HOME/.proto";
export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH";

eval "$(proto activate zsh)"
eval "$(proto completions)"

################################################################################
# pnpm
################################################################################

# pnpm
export PNPM_HOME="/Users/$USER/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

################################################################################
# fzf
################################################################################

# command-line fuzzy finder
# https://github.com/junegunn/fzf
command -v fzf >/dev/null && source <(fzf --zsh)

################################################################################
# fastfetch
################################################################################

command -v fastfetch >/dev/null && fastfetch && echo ""
