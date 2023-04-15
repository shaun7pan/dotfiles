#!/usr/bin/env bash
#
if [[ $# -eq 1 ]]; then
  selected=$1
else
  selected=$(find "$HOME"/.config "$HOME"/development/filcf "$HOME"/development/filk8s /Users/a560827/myworkspace -mindepth 1 -maxdepth 1 -type d | fzf-tmux -p 60%,50%)
fi

if [[ -z $selected ]]; then
  exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
  tmux new-session -s "$selected_name" -c "$selected"
  exit 0
fi

if ! tmux has-session -t="$selected_name" 2>/dev/null; then
  #echo "Creating new tmux session $selected_name"
  tmux new-session -ds "$selected_name" -c "$selected"
fi

# if in tmux, switch client to session
if [[ "$TERM" =~ "screen".* ]]; then
  tmux switch-client -t "$selected_name"
  exit 0
else # if not in tmux, attach to session
  tmux attach-session -t "$selected_name"
  exit 0
fi
