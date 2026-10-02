#!/usr/bin/env bash
set -euo pipefail

if [[ $# == 1 && $1 == --help ]]; then
  printf 'Usage: ps-kill [filter]\nPress Enter in fzf to send SIGTERM to a process and its descendants.\n'
  exit 0
fi

if [[ $# -gt 1 ]]; then
  printf 'Usage: ps-kill [filter]\n' >&2
  exit 2
fi

snapshot=$(ps -wwax -o pid=,ppid=,user=,lstart=,args=)
candidates=$(awk -v self="$$" '
  {
    pid = $1
    parents[pid] = $2
    users[pid] = $3
    command = $0
    for (field = 1; field <= 8; field++)
      sub(/^[[:space:]]*[^[:space:]]+[[:space:]]*/, "", command)
    sub(/^[^[:space:]]*\//, "", command)
    gsub(/\/nix\/store\/[a-z0-9]{32}-[^[:space:]]+\/(bin|libexec)\//, "", command)
    gsub(/\/nix\/store\/[a-z0-9]{32}-/, "/nix/store/…-", command)
    commands[pid] = command
  }
  END {
    for (pid = self; pid > 0 && !protected[pid]; pid = parents[pid])
      protected[pid] = 1
    for (pid in commands)
      if (pid > 1 && !protected[pid])
        printf "%7s  %-12s  %s\n", pid, users[pid], commands[pid]
  }
' <<< "$snapshot")

if [[ -z $candidates ]]; then
  printf 'No selectable processes.\n'
  exit 0
fi

if selected=$(FZF_DEFAULT_OPTS='' FZF_DEFAULT_OPTS_FILE='' fzf \
  --exact +i --query="${1-}" --nth=3.. --no-multi --no-select-1 --no-exit-0 \
  --height=80% --layout=reverse --border --no-hscroll --highlight-line \
  --prompt='ps-kill> ' \
  --header=$'    PID  USER          COMMAND\nEnter: kill tree | Esc: cancel | Ctrl+P: toggle details' \
  --preview="ps -p {1} -o pid,ppid,user,%cpu,%mem,etime; printf '\\nFULL COMMAND\\n'; ps -ww -p {1} -o args=" \
  --preview-window=down,45%,wrap --preview-label=' Process details ' \
  --bind=ctrl-p:toggle-preview \
  <<< "$candidates"); then
  read -r selected_pid _ <<< "$selected"
else
  status=$?
  case $status in
    1|130) exit 0 ;;
    *) exit "$status" ;;
  esac
fi

selected_start=$(awk -v pid="$selected_pid" '
  $1 == pid { print $4, $5, $6, $7, $8 }
' <<< "$snapshot")
if [[ ! $selected_pid =~ ^[0-9]+$ || -z $selected_start ]]; then
  printf 'Invalid process selection.\n' >&2
  exit 1
fi

snapshot=$(ps -wwax -o pid=,ppid=,user=,lstart=,args=)
# Build a fresh tree, exclude our ancestry, and visit children before parents.
targets=$(awk -v root="$selected_pid" -v start="$selected_start" -v self="$$" '
  function visit(pid, child) {
    if (visited[pid]++) return
    for (child in parents)
      if (parents[child] == pid) visit(child)
    print rows[pid]
  }
  { parents[$1] = $2; rows[$1] = $0; starts[$1] = $4 " " $5 " " $6 " " $7 " " $8 }
  END {
    for (pid = self; pid > 0 && !protected[pid]; pid = parents[pid])
      protected[pid] = 1
    if (root <= 1 || protected[root] || starts[root] != start) exit 1
    visit(root)
  }
' <<< "$snapshot") || {
  printf 'Selected process exited, changed, or is protected. Nothing killed.\n' >&2
  exit 1
}

printf 'SIGTERM targets (descendants first):\n'
awk '
  {
    printf "\nPID %s | Parent %s | User %s\n", $1, $2, $3
    for (field = 1; field <= 8; field++)
      sub(/^[[:space:]]*[^[:space:]]+[[:space:]]*/, "", $0)
    printf "Command: %s\n", $0
  }
' <<< "$targets"
kill_command=$(type -P kill)
runner=()
if (( EUID != 0 )); then
  sudo -v
  runner=(sudo --)
fi

status=0
while read -r pid _ _ weekday month day time year _; do
  expected_start="$weekday $month $day $time $year"
  current_start=$(ps -p "$pid" -o lstart= | awk '{$1=$1; print}') || current_start=
  if [[ -z $current_start ]]; then
    printf 'PID %s already exited; skipped.\n' "$pid"
  elif [[ $current_start != "$expected_start" ]]; then
    printf 'PID %s changed since selection; skipped.\n' "$pid" >&2
    status=1
  elif ! "${runner[@]}" "$kill_command" -TERM -- "$pid"; then
    printf 'Failed to terminate PID %s.\n' "$pid" >&2
    status=1
  fi
done <<< "$targets"
exit "$status"
