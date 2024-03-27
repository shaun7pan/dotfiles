#!/usr/bin/env bash

set -eEuo pipefail

current_session_name=$(tmux display-message -p '#S')
if [[ "$current_session_name" == "popup" ]]; then
  exit 0
fi

selected_name=$(tmux list-sessions -F '#{session_name}' | fzf-tmux -p 60%,50%)

# if in tmux, switch client to session
if [[ -n $selected_name ]]; then
  if [[ "$TERM" =~ "screen".* ]]; then
    tmux switch-client -t "$selected_name"
  else # if not in tmux, attach to session
    tmux attach-session -t "$selected_name"
  fi
fi
