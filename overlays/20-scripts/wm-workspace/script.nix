{ pkgs }:
''
  #!/usr/bin/env bash

  echo $1
  echo $2
  echo $3

  # Check if enough arguments are provided
  if [ "$#" -lt 2 ]; then
      echo "Usage: $0 <workspace> <window_title1> [<window_title2> ...]"
      exit 1
  fi

  TARGET_WORKSPACE="$1"
  shift  # Remove first argument (workspace) so that only titles remain

  WINDOW_TITLES=("$@")

  for TITLE in "''${WINDOW_TITLES[@]}"; do
      WINDOW_IDS=$(xdotool search --name "$TITLE")

      if [ -n "$WINDOW_IDS" ]; then
          for WINDOW_ID in $WINDOW_IDS; do
              i3-msg "[id=$WINDOW_ID] move to workspace $TARGET_WORKSPACE"
          done
      else
          echo "No window found with title: $TITLE"
      fi
  done
''
