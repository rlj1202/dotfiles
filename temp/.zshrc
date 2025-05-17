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
autoload -Uz compinit && compinit

setopt prompt_subst

function prompt_user_host() {
    echo -n "%B%(!.%{$fg[red]%}.%{$fg[green]%})%n@%m%{$reset_color%}"
}

function prompt_current_dir() {
    echo -n "%B%{$fg[blue]%}%~%{$reset_color%}"
}

function prompt_time() {
    echo -n "%D %D{%H:%M:%S}"
}

function prompt_vcs() {
    # Check cwd is tracked by git or not
    if ! git rev-parse --git-dir &> /dev/null; then
        return
    fi

    local branch=""

    local ahead=0
    local behind=0
    local staged=0
    local changed=0
    local deleted=0
    local unmerged=0
    local untracked=0
    local ignored=0

    local tracking_status=""
    local local_status=""

    local flag
    local key
    local value
    local xy
    local rest
    while read -u 0 -k 1 flag; do
        case $flag in
            "#")
                read key value
                case $key in
                    branch.oid) ;;
                    branch.head)
                        if [[ "$value" != "(detached)" ]]; then branch="$value"; fi
                        ;;
                    branch.upstream) ;;
                    branch.ab)
                        read ahead behind < <(echo $value | sed 's/[+-]//g')
                        ;;
                esac
                ;;
            "1"|"2")
                # Ordinary change entries
                # Renamed or copied entries
                read xy rest

                case $xy in
                    [^.]?)
                        (( staged++ ))
                        ;;
                esac

                case $xy in
                    ?D)
                        (( deleted++ ))
                        ;;
                    ?M|?T|?A|?R|?C|*)
                        (( changed++ ))
                        ;;
                esac
                ;;
            "u")
                # Unmerged entries
                read rest
                (( unmerged++ ))
                ;;
            "?")
                # Untracked items
                read rest
                (( untracked++ ))
                ;;
            "!")
                # Ignored items
                read rest
                (( ignored++ ))
                ;;
        esac
    done < <(git status --porcelain=v2 --branch)

    branch="%{$fg[yellow]%}$branch"
    branch+="%{$reset_color%}"

    tracking_status="%{$fg[magenta]%}$tracking_status"
    if (( ahead > 0 )); then tracking_status+="↑$ahead"; fi
    if (( behind > 0 )); then tracking_status+="↓$behind"; fi
    tracking_status+="%{$reset_color%}"

    if (( staged > 0 )); then local_status+="%{$fg[red]%}●$staged"; fi
    if (( unmerged > 0 )); then local_status+="%{$fg[red]%}✖$unmerged"; fi
    if (( changed > 0 )); then local_status+="%{$fg[blue]%}✚$changed"; fi
    if (( deleted > 0 )); then local_status+="%{$fg[blue]%}-$deleted"; fi
    if (( untracked > 0 )); then local_status+="%{$fg[cyan]%}…$untracked"; fi
    if [[ -z "$local_status" ]]; then local_status="%{$fg[green]%}✔"; fi
    local_status+="%{$reset_color%}"

    echo -n "git:($branch$tracking_status|$local_status)"
}

function prompt_proto() {
    command -v proto >/dev/null || return

    setopt localoptions pipefail

    echo -n "proto:("
    echo -n "%{$fg[yellow]%}"
    echo -n - "$(proto status --json 2> /dev/null | jq -r '. | to_entries | map(.key + "@" + .value.resolved_version) | join(", ")' || echo - -)"
    echo -n "%{$reset_color%}"
    echo -n ")"
}

function prompt_kubectl() {
    command -v kubectl >/dev/null || return

    local kube_context
    local kube_namespace

    kube_context="$(kubectl config current-context 2>/dev/null)"
    kube_context="${kube_context:-N/A}"

    kube_namespace="$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)"
    kube_namespace="${kube_namespace:-default}"

    echo -n "kube:("
    echo -n "%{$fg[red]%}$kube_context%{$reset_color%}:%{$fg[cyan]%}$kube_namespace%{$reset_color%}"
    echo -n ")"
}

function build_prompt() {
    local segments=(
        "$(prompt_user_host)"
        "$(prompt_current_dir)"
        # FIXME:
        "TEMPORARY"
        "$(prompt_vcs)"
        "$(prompt_proto)"
        "$(prompt_kubectl)"
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
# homebrew
################################################################################

if [[ $(uname) = 'Darwin' ]]; then
  alias brew='arch -arm64 /opt/homebrew/bin/brew'
  alias ibrew='arch -x86_64 /usr/local/bin/brew'
fi

################################################################################
# proto
################################################################################

export PROTO_HOME="$HOME/.proto";
export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH";

command -v proto >/dev/null && eval "$(proto activate zsh)"
command -v proto >/dev/null && eval "$(proto completions)"

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
# fzf, command-line fuzzy finder
#
# https://github.com/junegunn/fzf
################################################################################

command -v fzf >/dev/null && source <(fzf --zsh)

################################################################################
# fastfetch
################################################################################

command -v fastfetch >/dev/null && fastfetch && echo ""
