#!/usr/bin/env bash

set -eEuo pipefail

current_session_name=$(tmux display-message -p '#S')
if [[ "$current_session_name" == "popup" ]]; then
  tmux detach-client -s popup
  tmux switch-client -t popup
fi
