{}: ''
  #!/usr/bin/env sh

  # Usage:
  #   t

  # If the target directory has a .tmux file, that file will be executed
  # (and sent the <session> name as the first argument) instead of the default
  # window setup (explained below). An example .tmux file may look like
  # so:
  #   #!/usr/bin/env sh
  #   SESSION=$1
  #   tmux new-session -s "$SESSION" -n editor -d
  #   tmux send-keys 'e' C-m ':CtrlP' C-m
  #   tmux new-window -n shell -t "$SESSION"
  #   tmux select-window -t "$SESSION":1

  # If there is no .tmux file, the default window setup is as follows:
  # editor  - runs $EDITOR right away

  set -e

  SESSION="''${PWD##*/}"
  SESSION=''${SESSION//\./}

  _safe_window() {
    if [ -x "$2" ]; then
      direnv exec / tmux new-window -n "$1" -t "$SESSION"
      tmux send-keys "$2" C-m
    fi
  }

  if ! (tmux list-sessions | cut -d':' -f1 | grep -q ^"$SESSION"\$); then
    if [ -L "$PWD"/.tmux ] && [ -e "$PWD"/.tmux ] || [ -x "$PWD"/.tmux ]; then
      "$PWD"/.tmux "$SESSION"
    else
      direnv exec / tmux new-session -s "$SESSION" -n editor -d
      tmux send-keys "$EDITOR" C-m #':CtrlP' C-m
      _safe_window bash bash

      tmux select-window -t "$SESSION":1
    fi
  fi

  if [ -z "$TMUX" ]; then
    direnv exec / tmux attach -t "$SESSION"
  else
    direnv exec / tmux switch-client -t "$SESSION"
  fi
''
