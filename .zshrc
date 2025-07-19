################################################################################
# env vars
################################################################################

export DOTFILES=${DOTFILES:-~/dotfiles}

export PATH=$HOME/bin:$DOTFILES/bin:/usr/local/bin:$PATH

################################################################################
# bindkey
################################################################################

bindkey -v
bindkey -v "^?" backward-delete-char # backspace
bindkey "^[[3~" delete-char # delete key

################################################################################
# aliases
################################################################################

# alias ls='ls -G'
# alias lsa='ls -lah'
# alias l='ls -lah'
# alias ll='ls -lh'
# alias la='ls -lAh'

alias eza='eza -bF --git --hyperlink --icons'

alias l='eza'
alias ll='eza -l'
alias la='eza -a'
alias lla='eza -la'

################################################################################
# zsh-async
################################################################################

source $DOTFILES/zsh/zsh-async/async.zsh
async_init

################################################################################
# prompt
################################################################################

# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html

autoload -U colors && colors
autoload -Uz compinit && compinit
autoload -U add-zsh-hook

setopt prompt_subst

# Using the shell is much faster than `git rev-parse --git-dir` or `jj root`
#
# Examples:
#   upwards .jj
#   upwards .git
#   upwards .jj .git
function upwards() {
    local curDir="/$PWD"
    while [[ -n "$curDir" ]]; do
        for target in $@; do
            [[ -e "$curDir/$target" ]] && { echo $target ; return 0 ; }
        done
        curDir="${curDir%/*}"
    done

    return 1
}

function prompt_user_host() {
    echo -n "%B%(!.%{$fg[red]%}.%{$fg[green]%})%n@%m%{$reset_color%}"
}

function prompt_current_dir() {
    echo -n "%B%{$fg[blue]%}%~%{$reset_color%}"
}

function prompt_time() {
    echo -n "%D %D{%H:%M:%S}"
}

function prompt_git() {
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
            ("#")
                read key value
                case $key in
                    (branch.oid)
                        branch="$(git rev-parse --short $value)"
                        ;;
                    (branch.head)
                        if [[ "$value" != "(detached)" ]]; then
                            branch="$value"
                        else
                            branch+="(detached)"
                        fi
                        ;;
                    (branch.upstream) ;;
                    (branch.ab)
                        read ahead behind < <(echo $value | sed 's/[+-]//g')
                        ;;
                esac
                ;;
            ("1"|"2")
                # Ordinary change entries
                # Renamed or copied entries
                read xy rest

                case $xy in
                    ([^.]?)
                        (( staged++ ))
                        ;;
                esac

                case $xy in
                    (?D)
                        (( deleted++ ))
                        ;;
                    (?.) ;;
                    (?M|?T|?A|?R|?C|*)
                        (( changed++ ))
                        ;;
                esac
                ;;
            ("u")
                # Unmerged entries
                read rest
                (( unmerged++ ))
                ;;
            ("?")
                # Untracked items
                read rest
                (( untracked++ ))
                ;;
            ("!")
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

function prompt_jj() {
    command -v jj >/dev/null || return
    upwards .jj >/dev/null || return

    # https://github.com/jj-vcs/jj/wiki/Shell-Prompt
    # --ignore-working-copy: avoid inspecting $PWD and concurrent snapshotting which could create divergent commits
    local rev_info="$(
        jj --ignore-working-copy --no-pager log --no-graph --color=always -r @ -T \
            'separate(
                " ",
                format_short_change_id_with_hidden_and_divergent_info(self),
                format_short_commit_id(commit_id),
                bookmarks,
                if(conflict, label("conflict", "conflict"))
            )' 2>/dev/null | sed -E $'s/(\e\\[[0-9]+(;[0-9]+)*m)/%{\\1%}/g'
    )"
    rev_info+="%{$reset_color%}"

    local added=0
    local deleted=0
    local modified=0
    while read diff_status diff_path; do
        case $diff_status in
          (A) (( added++ )) ;;
          (D) (( deleted++ )) ;;
          (M) (( modified++ )) ;;
        esac
    done < <(jj --ignore-working-copy diff -s)

    local rev_status=""
    if (( added > 0 )); then rev_status+="%{$fg[green]%}+$added"; fi
    if (( deleted > 0 )); then rev_status+="%{$fg[red]%}-$deleted"; fi
    if (( modified > 0 )); then rev_status+="%{$fg[blue]%}*$modified"; fi
    if [[ -z "$rev_status" ]]; then rev_status="%{$fg[green]%}empty"; fi
    rev_status+="%{$reset_color%}"

    echo -n "jj:($rev_info|$rev_status)"
}

function prompt_proto() {
    command -v proto >/dev/null || return

    setopt localoptions pipefail

    typeset -a locals
    typeset -A versions
    typeset -A installed
    typeset -a proto_status

    while read name version is_installed; do
        versions[$name]=$version
        installed[$name]=$is_installed
    done < <(
        proto status --json -c all 2> /dev/null \
        | jq -r 'to_entries[] | (.key + " " + .value.resolved_version + " " + ( .value.is_installed | tostring ))'
    )

    while read name version is_installed; do
        locals+=($name)
        versions[$name]=$version
        installed[$name]=$is_installed
    done < <(
        proto status --json -c upwards 2> /dev/null \
        | jq -r 'to_entries[] | (.key + " " + .value.resolved_version + " " + ( .value.is_installed | tostring ))'
    )

    for name in ${(k)versions}; do
        version=${versions[$name]}
        is_installed=${installed[$name]}
        color="$( (( ${locals[(I)$name]} )) && echo 'yellow' || echo 'red' )"
        proto_status+=("%{$fg[$color]%}$name@$version$( [[ $is_installed = 'false' ]] && echo '!' )%{$reset_color%}")
    done

    if [[ ${#proto_status} = 0 ]]; then
        proto_status+=("%{$fg[yellow]%}-%{$reset_color%}")
    fi

    echo -n "proto:("
    echo -n - "${(j:|:)proto_status}"
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

function gen_async_prompt() {
    local prompt_org="$1"

    echo "$(cat <<EOF
        async_${prompt_org}_info=''

        function async_${prompt_org}_callback() {
            async_${prompt_org}_info="\${3}"
            zle reset-prompt
        }

        function async_${prompt_org}_do() {
            cd -q \$1
            ${prompt_org}
        }

        function async_${prompt_org}_precmd() {
            async_flush_jobs async_${prompt_org}_job
            async_job async_${prompt_org}_job async_${prompt_org}_do \$PWD
        }

        function async_${prompt_org}() {
            echo -n "\${async_${prompt_org}_info}"
        }

        async_start_worker async_${prompt_org}_job
        async_register_callback async_${prompt_org}_job async_${prompt_org}_callback
        add-zsh-hook precmd async_${prompt_org}_precmd
EOF
    )"
}

eval "$(gen_async_prompt prompt_git)"
eval "$(gen_async_prompt prompt_jj)"
eval "$(gen_async_prompt prompt_proto)"
eval "$(gen_async_prompt prompt_kubectl)"

function build_prompt() {
    local segments=(
        "$(prompt_user_host)"
        "$(prompt_current_dir)"
        "$(async_prompt_git)"
        "$(async_prompt_jj)"
        "$(async_prompt_proto)"
        "$(async_prompt_kubectl)"
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
# iterm2
################################################################################

source $DOTFILES/zsh/.iterm2_shell_integration.zsh

################################################################################
# zsh-autosuggestions
################################################################################

source $DOTFILES/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

################################################################################
# zsh-syntax-highlighting
################################################################################

source $DOTFILES/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

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
  (*":$PNPM_HOME:"*) ;;
  (*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

################################################################################
# fzf, command-line fuzzy finder
#
# https://github.com/junegunn/fzf
################################################################################

command -v fzf >/dev/null && source <(fzf --zsh)

################################################################################
# orbstack
################################################################################

# command-line tools and integration
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

################################################################################
# zshrc.local
################################################################################

if [[ -f ~/.zshrc.local ]]; then source ~/.zshrc.local; fi

################################################################################
# lima
################################################################################

command -v limactl >/dev/null && source <(limactl completion zsh)

################################################################################
# sdkman
################################################################################

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

################################################################################
# atuin
################################################################################

command -v atuin >/dev/null && eval "$(atuin init zsh)"

################################################################################
# zoxide
################################################################################

command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

################################################################################
# miscellaneous
################################################################################

alias cow='fortune | cowsay | lolcat'
alias qrviu='qrencode -o - | viu -w 60 -'

################################################################################
# fastfetch
################################################################################

command -v fastfetch >/dev/null && fastfetch
cow
echo ""
