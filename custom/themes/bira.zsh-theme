local return_code="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"
local user_host="%B%(!.%{$fg[red]%}.%{$fg[green]%})%n@%m%{$reset_color%} "
local user_symbol='%(!.#.$)'
local current_dir="%B%{$fg[blue]%}%~ %{$reset_color%}"
local conda_prompt='$(conda_prompt_info)'

local vcs_branch='$(git_prompt_info)$(hg_prompt_info)'
local rvm_ruby='$(ruby_prompt_info)'
local venv_prompt='$(virtualenv_prompt_info)'

function prompt_padding() {
    local segment="$($1)"

    if [[ -n $segment ]]; then
        segment+=' '
    fi

    echo $segment
}

if [[ "${plugins[@]}" =~ 'kube-ps1' ]]; then
    local kube_prompt='$(prompt_padding kube_ps1)'
else
    local kube_prompt=''
fi

if [[ "${plugins[@]}" =~ 'aws' ]]; then
    local aws_prompt='$(prompt_padding aws_prompt_info)'
else
    local aws_prompt=''
fi

if [[ "${plugins[@]}" =~ 'nvm' ]]; then
    local nvm_prompt='$(prompt_padding nvm_prompt_info)'
else
    local nvm_prompt=''
fi

local time_prompt='%*'

ZSH_THEME_RVM_PROMPT_OPTIONS="i v g"

PROMPT="╭─${conda_prompt}${user_host}${current_dir}${rvm_ruby}${vcs_branch}${venv_prompt}${aws_prompt}${nvm_prompt}${kube_prompt}${time_prompt}
╰─%B${user_symbol}%b "
RPROMPT="%B${return_code}%b"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[yellow]%}git:("
ZSH_THEME_GIT_PROMPT_SUFFIX=") %{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}●%{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[yellow]%}"

ZSH_THEME_HG_PROMPT_PREFIX="$ZSH_THEME_GIT_PROMPT_PREFIX"
ZSH_THEME_HG_PROMPT_SUFFIX="$ZSH_THEME_GIT_PROMPT_SUFFIX"
ZSH_THEME_HG_PROMPT_DIRTY="$ZSH_THEME_GIT_PROMPT_DIRTY"
ZSH_THEME_HG_PROMPT_CLEAN="$ZSH_THEME_GIT_PROMPT_CLEAN"

ZSH_THEME_RUBY_PROMPT_PREFIX="%{$fg[red]%}ruby:("
ZSH_THEME_RUBY_PROMPT_SUFFIX=") %{$reset_color%}"

ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX="%{$fg[green]%}venv:("
ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX=") %{$reset_color%}"
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
