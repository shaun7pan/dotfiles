source $(brew --prefix)/etc/bash_completion
eval "$(fasd --init auto)"

if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

alias vim='nvim'
alias vi='nvim'

#fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
export FZF_COMPLETION_TRIGGER='**'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
#export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --preview "bat --style=numbers --color=always --line-range :500 {}"'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# fe [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fv() {
  IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
  [[ -n "$files" ]] && ${EDITOR:-nvim} "${files[@]}"
}

# fd - cd to selected directory
fcd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

# alternative using ripgrep-all (rga) combined with fzf-tmux preview
# This requires ripgrep-all (rga) installed: https://github.com/phiresky/ripgrep-all
# This implementation below makes use of "open" on macOS, which can be replaced by other commands if needed.
# allows to search in PDFs, E-Books, Office documents, zip, tar.gz, etc. (see https://github.com/phiresky/ripgrep-all)
# find-in-file - usage: fif <searchTerm> or fif "string with spaces" or fif "regex"
fif() {
    if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
    local file
    file="$(rga --max-count=1 --ignore-case --files-with-matches --no-messages "$*" | fzf-tmux +m --preview="rga --ignore-case --pretty --context 10 '"$*"' {}")" && echo "opening $file" && nvim "$file" || return 1;
}

# Check if remote repo is existed and clone it if not.
ff() {
  local dir
  local repos
  local username
  local password
  local file
  local now
  username=$(your_username)
  password=$(your_password)
  file="$HOME/.repos.txt"

  if [ ! -f "$file" ] || [ -z "$(cat ${file})" ] || [ "`find $file -mtime +1`" ]; then
      repos=$(curl -su "${username}:${password}" \
      -L https://<your_api_url> \
      | jq -r .values[].name)
      echo -e "${repos}" > $file
  fi
  modified=$(stat -f "%m%t%Sm %N" $HOME/.repos.txt | cut -f2| cut -d'/' -f1)
  now=$(date +'%b %d %H:%M:%S %Y')
  dir=$(cat ${file} | fzf +m --header "[Updated @ ${now}]")

  [ ! -d "$HOME/development/${dir}" ] &&
  git clone <your_repo_url>/${dir}.git ~/development/${dir}
  [ ! -z "$dir" ] && cd "$HOME/development/${dir}"
}

# open bitbucket repo url
b() {
  local repo
  local url
  local file
  file="$HOME/.repos.txt"
  repo="$(cat ${file} | fzf +m)"
  url="<your_repo_url>"
  [ ! -z $repo ] && open $url
}

# v - open files in ~/.viminfo
#v() {
#  local files
#  files=$(grep '^>' ~/.viminfo | cut -c3- |
#          while read line; do
#            [ -f "${line/\~/$HOME}" ] && echo "$line"
#          done | fzf-tmux -d -m -q "$*" -1) && vim ${files//\~/$HOME}
#}

# fasd & fzf change directory - open best matched file using `fasd` if given argument, filter output of `fasd` using `fzf` else
v() {
    [ $# -gt 0 ] && fasd -f -e ${EDITOR} "$*" && return
    local file
    file="$(fasd -Rfl "$1" | fzf -1 -0 --no-sort +m)" && vi "${file}" || return 1
}

# fasd & fzf change directory - jump using `fasd` if given argument, filter output of `fasd` using `fzf` else
unalias z
z() {
  [ $# -gt 0 ] && fasd_cd -d "$*" && return
  local dir
  dir="$(fasd -Rdl "$1" | fzf -1 -0 --no-sort +m)" && cd "${dir}" || return 1
}


# c - browse chrome history
c() {
  local cols sep google_history open
  cols=$(( COLUMNS / 3 ))
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
  fzf --ansi --multi | sed 's#.*\(https*://\)#\1#' | xargs $open > /dev/null 2> /dev/null
}

#ranger settings
# make ranger stop in the directory where it left when quiting
function ranger {
    local IFS=$'\t\n'
    local tempfile="$(mktemp -t tmp.XXXXXX)"
    local ranger_cmd=(
        command
        ranger
        --cmd="map Q chain shell echo %d > "$tempfile"; quitall"
    )

    ${ranger_cmd[@]} "$@"
    if [[ -f "$tempfile" ]] && [[ "$(cat -- "$tempfile")" != "$(echo -n `pwd`)" ]]; then
        cd -- "$(cat "$tempfile")" || return
    fi
    command rm -f -- "$tempfile" 2>/dev/null
}

alias ra='ranger --choosedir=$HOME/.rangerdir; LASTDIR=`cat $HOME/.rangerdir`; cd "$LASTDIR"'
export VISUAL=nvim
export EDITOR=nvim
if [ -n "$RANGER_LEVEL" ]; then export PS1="[ranger]$PS1"; fi

#lazygit

alias lg='lazygit'

chedit ()
{
    title=$(cheat -l | fzf -m | awk '{print $1}')
    cheat -e $title
}

msg ()
{
    local mail_file_name
    mail_file_name=$(find $HOME/Downloads -type f -name '*.msg' | fzf)
    $HOME/ExtractMsg.py "$mail_file_name" | nvim
}

alias lsmsg="find /Users/<userid>/Downloads -type f -name '*.msg' -exec ls {} \;"

cleanmsg () {

    find /Users/<userid>/Downloads  -type f -name '*.msg' -print0 |
    while IFS= read -r -d '' file; do
        printf 'DELETING %s\n' "$file"
        rm "$file"
    done
}


### forgit
source ~/forgit/forgit.plugin.sh

### autojump
[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh

#like normal autojump when used with arguments but displays an fzf prompt when used without
j() {
    if [[ "$#" -ne 0 ]]; then
        cd $(autojump $@)
        return
    fi
    cd "$(autojump -s | sort -k1gr | awk '$1 ~ /[0-9]:/ && $2 ~ /^\// { for (i=2; i<=NF; i++) { print $(i) } }' |  fzf --height 40% --reverse --inline-info)" 
}


# fshow - git commit browser (enter for show, ctrl-d for diff, ` toggles sort)
fshow() {
  local out shas sha q k
  while out=$(
      git log --graph --color=always \
          --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
      fzf --ansi --multi --no-sort --reverse --query="$q" \
          --print-query --expect=ctrl-d --toggle-sort=\`); do
    q=$(head -1 <<< "$out")
    k=$(head -2 <<< "$out" | tail -1)
    shas=$(sed '1,2d;s/^[^a-z0-9]*//;/^$/d' <<< "$out" | awk '{print $1}')
    [ -z "$shas" ] && continue
    if [ "$k" = ctrl-d ]; then
      git diff --color=always $shas | less -R
    else
      for sha in $shas; do
        git show --color=always $sha | less -R
      done
    fi
  done
}

# fshow - git commit browser
fshow2() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

# fkill - kill processes - list only the ones you can kill. Modified the earlier script.
fkill() {
    local pid 
    if [ "$UID" != "0" ]; then
        pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
    else
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    fi

    if [ "x$pid" != "x" ]
    then
        echo $pid | xargs kill -${1:-9}
    fi
}


# open bookmark url
alias bb='$HOME/.bb'


#tmux
alias tn='tmux new -s'
alias tls='tmux ls'
alias ta='tmux attach-session -t'
alias cl='clear'

source ~/.dotbare/dotbare.plugin.bash
alias config='dotbare'
_dotbare_completion_cmd config
