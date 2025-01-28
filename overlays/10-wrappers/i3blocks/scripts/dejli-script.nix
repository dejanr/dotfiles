{}: ''
  #!/usr/bin/env bash

  SCRIPT_TO_RUN=$1
  PID_FILE=$2
  LABEL=$3

  DEFAULT_COLOR="#FFFFFF"
  ACTIVE_COLOR="#DBC074"

  if [[ "$BLOCK_BUTTON" == "1" ]]; then
      if [[ -f "$PID_FILE" ]] then
          # Stop the script by killing the process
          rm -rf $PID_FILE
          echo "$LABEL"
          echo "$LABEL"
          echo "$DEFAULT_COLOR"
          exit 0
      else
          # Start the script and save its PID
          $SCRIPT_TO_RUN > /dev/null 2>&1 &
          disown
          echo "$LABEL"
          echo "$LABEL"
          echo "$ACTIVE_COLOR"
          exit 0
      fi
  fi

  if [[ -f "$PID_FILE" ]]; then
      echo "$LABEL"
      echo "$LABEL"
      echo "$ACTIVE_COLOR"
  else
      echo "$LABEL"
      echo "$LABEL"
      echo "$DEFAULT_COLOR"
  fi
''
