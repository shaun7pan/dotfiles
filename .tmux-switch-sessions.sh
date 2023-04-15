#/usr/bin/env bash

selected_name=$(tmux list-sessions -F '#{session_name}' | fzf-tmux -p 60%,50%)

# if in tmux, switch client to session
if [[ -n $selected_name ]]; then
  if [[ "$TERM" =~ "screen".* ]]; then
    tmux switch-client -t "$selected_name"
  else # if not in tmux, attach to session
    tmux attach-session -t "$selected_name"
  fi
fi
