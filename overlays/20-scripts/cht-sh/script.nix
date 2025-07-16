{ pkgs }:
''
  #!/usr/bin/env bash

  topic_constraint="none"

  while [[ "$#" -gt 0 ]];do
  case $1 in
    l|lang)
    topic_constraint="lang"
    shift;;
  esac
  done

  topic=""
  if [[ "$topic_constraint" == "lang" ]]; then
    topic=$(printf "go\nrust\nc" | ${pkgs.fzf}/bin/fzf)
    stty sane
  else
    topic=$(curl -s cht.sh/:list | ${pkgs.fzf}/bin/fzf)
    stty sane
  fi

  if [[ -z "$topic" ]]; then
    exit 0
  fi

  sheet=$(curl -s cht.sh/$topic/:list | ${pkgs.fzf}/bin/fzf)

  if [[ -z "$sheet" ]]; then
    curl -s cht.sh/$topic?style=rrt | less -R
    exit 0
  fi

  curl -s cht.sh/$topic/$sheet?style=rrt  | less -R
''
