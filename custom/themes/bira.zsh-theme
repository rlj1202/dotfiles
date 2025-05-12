# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html

function prompt_conda() {
    echo -n "$(conda_prompt_info)"
}

function prompt_user_host() {
    echo -n "%B%(!.%{$fg[red]%}.%{$fg[green]%})%n@%m%{$reset_color%}"
}

function prompt_current_dir() {
    echo -n "%B%{$fg[blue]%}%~%{$reset_color%}"
}

function prompt_ruby() {
    echo -n "$(ruby_prompt_info)"
}

function prompt_vcs() {
    # https://github.com/ohmyzsh/ohmyzsh/issues/12328
    echo -n "$(_omz_git_prompt_info)$(hg_prompt_info)"
}

function prompt_venv() {
    echo -n "$(virtualenv_prompt_info)"
}

function prompt_aws() {
    [[ "${plugins[@]}" =~ 'aws' ]] || return
    echo -n "$(aws_prompt_info)"
}

function prompt_nvm() {
    [[ "${plugins[@]}" =~ 'nvm' ]] || return
    echo -n "$(nvm_prompt_info)"
}

function prompt_volta() {
    [[ "${plugins[@]}" =~ 'volta' ]] || return
    echo -n "volta:("
    echo -n "%{$fg[yellow]%}"
    echo -n "$(volta list --format plain -c node | cut -f 2 -d ' ' | tail -n 1)"
    echo -n "%{$reset_color%}"
    echo -n ")"
}

function prompt_proto() {
    local protoStatus
    protoStatus="$(proto status --json 2> /dev/null)" || return

    echo -n "proto:("
    echo -n "%{$fg[yellow]%}"
    echo -n "$(echo "$protoStatus" | jq -r '. | to_entries | map(.key + "@" + .value.resolved_version) | join(", ")')"
    echo -n "%{$reset_color%}"
    echo -n ")"
}

function prompt_kube() {
    [[ "${plugins[@]}" =~ 'kube-ps1' ]] || return
    echo -n "$(kube_ps1)"
}

function prompt_time() {
    echo -n "%D %*"
}

function build_prompt() {
    local segments=(
        "$(prompt_conda)"
        "$(prompt_user_host)"
        "$(prompt_current_dir)"
        "$(prompt_ruby)"
        "$(prompt_vcs)"
        "$(prompt_venv)"
        "$(prompt_aws)"
        "$(prompt_nvm)"
        "$(prompt_volta)"
        "$(prompt_proto)"
        "$(prompt_kube)"
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

local return_code="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"

PROMPT='$(build_prompt)'
RPROMPT="%B${return_code}%b"

ZSH_THEME_GIT_PROMPT_PREFIX="git:(%{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%})"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}●%{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[yellow]%}"

ZSH_THEME_HG_PROMPT_PREFIX="$ZSH_THEME_GIT_PROMPT_PREFIX"
ZSH_THEME_HG_PROMPT_SUFFIX="$ZSH_THEME_GIT_PROMPT_SUFFIX"
ZSH_THEME_HG_PROMPT_DIRTY="$ZSH_THEME_GIT_PROMPT_DIRTY"
ZSH_THEME_HG_PROMPT_CLEAN="$ZSH_THEME_GIT_PROMPT_CLEAN"

ZSH_THEME_RVM_PROMPT_OPTIONS="i v g"

ZSH_THEME_RUBY_PROMPT_PREFIX="%{$fg[red]%}ruby:("
ZSH_THEME_RUBY_PROMPT_SUFFIX=")%{$reset_color%}"

ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX="%{$fg[green]%}venv:("
ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX=")%{$reset_color%}"
ZSH_THEME_VIRTUALENV_PREFIX="$ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX"
ZSH_THEME_VIRTUALENV_SUFFIX="$ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX"

ZSH_THEME_AWS_PROFILE_PREFIX="aws:(%{$fg[magenta]%}"
ZSH_THEME_AWS_PROFILE_SUFFIX="%{$reset_color%})"
ZSH_THEME_AWS_DIVIDER=" "
ZSH_THEME_AWS_REGION_PREFIX="region:(%{$fg[magenta]%}"
ZSH_THEME_AWS_REGION_SUFFIX="%{$reset_color%})"

ZSH_THEME_NVM_PROMPT_PREFIX="nvm:(%{$fg[yellow]%}"
ZSH_THEME_NVM_PROMPT_SUFFIX="%{$reset_color%})"

KUBE_PS1_PREFIX="kube:("
