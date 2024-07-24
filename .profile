#!/usr/local/env bash
# shellcheck disable=1091,2046,2142,2116,1090,2034,2236,2068,2002
#
export EDITOR=nvim

## disable default shell warning
#https://apple.stackexchange.com/questions/371997/suppressing-the-default-interactive-shell-is-now-zsh-message-in-macos-catalina
export BASH_SILENCE_DEPRECATION_WARNING=1

## source env
source ~/.profile_env
eval "$(/opt/homebrew/bin/brew shellenv)"

## gpg-agent
if ! [ -S "$HOME/.gnupg/S.gpg-agent" ]; then
  eval "$(gpg-agent --daemon)"
fi

## git completion
if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

## git prompt
# source ~/.git-prompt.sh

# ANSI colors: http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/x329.html
# RED="\[\033[0;31m\]"
# YELLOW="\[\033[0;33m\]"
# GREEN="\[\033[0;32m\]"
# CYAN="\[\033[0;36m\]"
# LIGHT_GREY="\[\033[0;37m\]"
# DARK_GREY="\[\033[1;30m\]"
# NO_COLOUR="\[\033[0m\]"
#
# ## set prompt
# GIT_PS1_SHOWDIRTYSTATE=1
# GIT_PS1_SHOWCOLORHINTS=1
#
# PROMPT_COMMAND='__git_ps1 "\[\033[0;31m\]$GREEN\u@\h\[\033[0m\]:$CYAN\w\[\033[0m\]" "\\\$ \n$ "'

## bash completion
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"

## pass
source /opt/homebrew/etc/bash_completion.d/pass

# Set alias for users personal data store
alias mysecrets='PASSWORD_STORE_DIR=~/.my_secrets pass'

## ssh agent
source ~/.start-ssh-agent

alias s="source ~/.profile"

## neovim
alias lz="NVIM_APPNAME=lazyvim nvim"
alias vim='nvim'
alias vi='nvim'

## tmux
alias tn='tmux new -s'
alias tls='tmux ls'
alias ta='tmux attach-session'
alias cl='clear'
export TMUX_TMPDIR=$HOME/.tmux/tmp
#####
alias tt='~/dotfiles/.tmux-sessionizer.sh'
alias ts='~/dotfiles/.tmux-switch-sessions.sh'

## rust

#check out selected
gc() {
  git checkout "$(git branch -r | fzf --height 40% --reverse --inline-info | cut -d '/' -f 2)"
}

#delete selected
gdb() {
  git branch -D "$(git branch | fzf --height 40% --reverse --inline-info | tr -d ' ')"
}

#FILK8S-397# k8s config
export K8S_CONFIG_PATH=$HOME/development/FIL-Enterprise-Prod/TAPP200073_k8s-config
export K8S_CUSTOMERS_PATH=$HOME/development/FIL-Enterprise-Prod/TAPP200073_k8s-customers
export K8S_CUSTOMERS="$(cat "${K8S_CUSTOMERS_PATH}/customers/np1.json")"

## krew
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

## fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
--color=dark
--color=fg:-1,bg:-1,hl:#c678dd,fg+:#ffffff,bg+:#4b5263,hl+:#d858fe
--color=info:#98c379,prompt:#61afef,pointer:#be5046,marker:#e5c07b,spinner:#61afef,header:#61afef
'
# Preview file content using bat (https://github.com/sharkdp/bat)
export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# CTRL-/ to toggle small preview window to see the full command
# CTRL-Y to copy the command into clipboard using pbcopy
export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

## gnu-sed
PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"

## gnu-awk
PATH="/opt/homebrew/opt/gawk/libexec/gnubin:$PATH"

## autojump
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

j() {
  local preview_cmd="ls {2..}"
  if command -v eza &>/dev/null; then
    preview_cmd="eza -l -a --no-user --color=always {2}"
  fi

  if [[ $# -eq 0 ]]; then
    ## fix https://www.shellcheck.net/wiki/SC2164
    cd "$(autojump -s | awk -F: '/[0-9]:/ {print $1, $2}' | sort -k1gr | awk '$1 ~ /[0-9]/ && $2 ~ /^\s*\// {print $1, $2}' | fzf --height 40% --reverse --inline-info --preview "$preview_cmd" --preview-window down:50% | cut -d$' ' -f2- | sed 's/^\s*//')" || exit
  else
    cd $(autojump $@) || exit
  fi
}

# Check if remote repo is existed and clone it if not.
ffo() {
  local dir
  local gh_token
  local file
  local now
  gh_token=$(mysecrets github-token)
  file="$HOME/.github-repos.txt"

  if [ ! -f "$file" ] || [ -z "$(cat "${file}")" ] || [ "$(find "$file" -mtime +1)" ]; then
    SEARCH_STR="FIL-Enterprise-Prod/TSWM208037+in:full_name" GH_TOKEN=${gh_token} FILE_PATH=${file} cargo run --manifest-path "$HOME"/development/rust-fetch-repos/Cargo.toml --quiet
  fi
  modified=$(stat -f "%m%t%Sm %N" "${file}" | cut -f2 | cut -d'/' -f1)
  now=$(date +'%b %d %H:%M:%S %Y')
  repo_path=$(cat "${file}" | fzf +m --header "[Updated @ ${now}]")

  [ ! -d "$HOME/development/${repo_path}" ] &&
    git clone https://"${gh_token}"@github.com/"${repo_path}".git ~/development/"${repo_path}"
  [ -n "$repo_path" ] && tt "$HOME/development/${repo_path}"
}

# Check if remote repo is existed and clone it if not.
ff() {
  local dir
  local gh_token
  local file
  local now
  gh_token=$(mysecrets github-token)
  file="$HOME/.github-repos-new.txt"

  if [ ! -f "$file" ] || [ -z "$(cat "${file}")" ] || [ "$(find "$file" -mtime +1)" ]; then
    SEARCH_STR="FIL-Enterprise-Prod/TAPP200073+in:full_name" GH_TOKEN=${gh_token} FILE_PATH=${file} cargo run --manifest-path "$HOME"/development/rust-fetch-repos/Cargo.toml >/dev/null 2>/dev/null
  fi
  modified=$(stat -f "%m%t%Sm %N" "${file}" | cut -f2 | cut -d'/' -f1)
  now=$(date +'%b %d %H:%M:%S %Y')
  repo_path=$(cat "${file}" | fzf +m --header "[Updated @ ${now}]")

  [ ! -d "$HOME/development/${repo_path}" ] &&
    git clone https://"${gh_token}"@github.com/"${repo_path}".git ~/development/"${repo_path}"
  [ -n "$repo_path" ] && tt "$HOME/development/${repo_path}"
}

# Check if remote repo is existed and clone it if not.
fb() {
  local dir
  local username
  local password
  local file
  local now
  local pid
  username=$(mysecrets ad-username)
  password=$(mysecrets ad-password)
  file="$HOME/.repos.json"

  if [ ! -f "$file" ] || [ -z "$(cat "${file}")" ] || [ "$(find "$file" -mtime +1)" ]; then
    echo "{}" >"${file}"
    for pid in filcf filk8s; do
      curl -su "${username}:${password}" \
        -L https://bitbucket.bip.uk.fid-intl.com/rest/api/1.0/projects/${pid^^}/repos?limit=10000 |
        jq -r --arg pid $pid '.| {pid: "'$pid'", value: [.values[].name]}'
    done | jq -s '.| map(.pid + "/" + .value[])' >"${file}"
  fi
  modified=$(stat -f "%m%t%Sm %N" "${file}" | cut -f2 | cut -d'/' -f1)
  now=$(date +'%b %d %H:%M:%S %Y')
  repo_path=$(jq -r '.[]' "${file}" | fzf +m --header "[Updated @ ${now}]")
  # pid=$(jq -r '.[]| select(.value[]| contains ("'${dir}'"))|.pid' "${file}")

  [ ! -d "$HOME/development/${repo_path}" ] &&
    git clone ssh://git@bitbucket.bip.uk.fid-intl.com/"${repo_path}".git ~/development/"${repo_path}"
  [ -n "$repo_path" ] && tt "$HOME/development/${repo_path}"
}

# open bitbucket repo url
gg() {
  local file
  # file_old="$HOME/.github-repos.txt"
  file_new="$HOME/.github-repos-new.txt"
  # org_repo_path=$(cat "${file_old}" "${file_new}" | fzf +m)
  org_repo_path=$(cat "${file_new}" | fzf +m)
  url="https://github.com/${org_repo_path}.git"
  [ ! -z "$org_repo_path" ] && open "$url"
}

# open bitbucket repo url
gb() {
  local repo
  local url
  local file
  file="$HOME/.repos.json"
  pid_repo_combin=$(jq -r '.[]' "${file}" | fzf +m)
  pid=$(echo "$pid_repo_combin" | awk -F'/' '{print $1}')
  repo_name=$(echo "$pid_repo_combin" | awk -F'/' '{print $2}')
  url="https://bitbucket.bip.uk.fid-intl.com/projects/$pid/repos/${repo_name}/browse"
  [ ! -z "$repo_name" ] && open "$url"
}

# c - browse chrome history
c() {
  local cols sep google_history open
  cols=$((COLUMNS / 3))
  sep='{::}'

  if [ "$(uname)" = "Darwin" ]; then
    google_history="$HOME/Library/Application Support/Google/Chrome/Default/History"
    open=open
  else
    google_history="$HOME/.config/google-chrome/Default/History"
    open=xdg-open
  fi
  cp -f "$google_history" /tmp/h
  sqlite3 -separator $sep /tmp/h \
    "select substr(title, 1, $cols), url
     from urls order by last_visit_time desc" |
    awk -F $sep '{printf "%-'$cols's  \x1b[36m%s\x1b[m\n", $1, $2}' |
    fzf --ansi --multi | sed 's#.*\(https*://\)#\1#' | xargs $open >/dev/null 2>/dev/null
}

# open bookmark
alias b='BOOKMARK_FILE_PATH="$HOME/Library/Application\ Support/Google/Chrome/Default/Bookmarks" cargo run --quiet --manifest-path "$HOME/development/parse-chrome-bookmarks/Cargo.toml" >/dev/null'

#lazygit
alias lg='lazygit'
export LC_ALL=en_US.UTF-8

## alias
alias ll='ls -al'
alias python='python3'
alias gp='git p'
alias fproxy='. ~/.fmrproxy.sh'
alias zproxy='. ~/.zscalerproxy.sh'

## brew python
# export PATH="${HOME}/Library/Python/3.11/bin:$PATH"

## atlassian-stash
# This variable is used by the .set_prompt command and can be used to
# RED=31 : GREEN=32 : YELLOW=33 : BLUE=34 : PURPLE=35 : LIGHT BLUE=36
# COLOUR=32 . "$HOME/.set_prompt"

alias tpr='echo -e "---\nstash_url: https://$(git remote get-url origin | awk -F@ {'"'"'print $2'"'"'} | awk -F/ {'"'"'print $1'"'"'})\nusername: $(mysecrets ad-username)\npasswordeval: PASSWORD_STORE_DIR=~/.my_secrets pass ad-password" > ~/.stashconfig.yml &&  stash pull-request `echo $(__git_ps1) | sed s/[\(\|\)]//g` master --title "SKIPTEST TinyPR : `echo $(__git_ps1) | sed s/[\(\|\)]//g`" -d "### What: TinyPR for `echo $(__git_ps1) | sed s/[\(\|\)]//g`
#### Latest commit message:
`git log -1 --pretty=%B`
### How to review
Check diffs and merge
### Who can review
Not me
"'
alias wpr='echo -e "---\nstash_url: https://$(git remote get-url origin | awk -F@ {'"'"'print $2'"'"'} | awk -F/ {'"'"'print $1'"'"'})\nusername: $(mysecrets ad-username)\npasswordeval: PASSWORD_STORE_DIR=~/.my_secrets pass ad-password" > ~/.stashconfig.yml && stash pull-request `echo $(__git_ps1) | sed s/[\(\|\)]//g` master --title " WIP DONTMERGE YET: `echo $(__git_ps1) | sed s/[\(\|\)]//g`" -d "### What: PR for `echo $(__git_ps1) | sed s/[\(\|\)]//g`
#### Latest commit message:
`git log -1 --pretty=%B`
### How to review
Check diffs and merge
### Who can review
Not xxx or yyy
"'

# Avoid duplicates
HISTCONTROL=ignoredups:erasedups
# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend

# After each command, append to the history file and reread it
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"
# fproxy
zproxy

## starship prompt
eval "$(starship init bash)"

alias mysecrets='PASSWORD_STORE_DIR=~/.my_secrets pass'

alias ga='git add'
alias glo='git log --oneline --decorate'
# alias gd='git diff'
alias gs='git status'

alias kc='cd "$HOME"/development/FIL-Enterprise-Prod/TAPP200073_k8s-config'
alias kl='cd "$HOME"/development/FIL-Enterprise-Prod/TAPP200073_k8s-lifecycle'
alias kp='cd "$HOME"/development/FIL-Enterprise-Prod/TAPP200073_k8s-platform'

[ -z "$TMUX" ] && export TERM="xterm-256color"
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"

if which pyenv >/dev/null; then eval "$(pyenv init -)"; fi
if which pyenv-virtualenv-init >/dev/null; then eval "$(pyenv virtualenv-init -)"; fi

[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"
. "$HOME/.cargo/env"

# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
