{}: /* bash */ ''
  #!/usr/bin/env bash

  EXIT_NODE_NAME_PATTERN="''${1:-pattern}"
  TITLE="''${2:-title}"
  DEFAULT_COLOR="#FFFFFF"
  ACTIVE_COLOR="#DBC074"

  CURRENT_EXIT_NODE=$(tailscale status --json | jq -r --arg city "Belgrade" '.Peer[] | select(.Location.City == $city and .ExitNodeOption == true and .Active == true and .ExitNode == true) | .TailscaleIPs[0]')
  DESIRED_EXIT_NODE=$(tailscale status --json | jq -r --arg city "Belgrade" '.Peer[] | select(.Location.City == $city and .ExitNodeOption == true and .Active == true and .ExitNode == false) | .TailscaleIPs[0]')

  # Determine color and display state
  if [[ -n "$CURRENT_EXIT_NODE" && "$CURRENT_EXIT_NODE" != "" ]]; then
      echo "$TITLE"
      echo "$TITLE"
      echo "$ACTIVE_COLOR"
  else
      echo "$TITLE"
      echo "$TITLE"
      echo "$DEFAULT_COLOR"
  fi

  # Handle click actions
  case $BLOCK_BUTTON in
      1)  # Toggle
          if [[ -n "$CURRENT_EXIT_NODE" && "$CURRENT_EXIT_NODE" != "" ]]; then
              sudo tailscale set --exit-node=
          elif [[ -n "$DESIRED_EXIT_NODE" ]]; then
              sudo tailscale set --exit-node="$DESIRED_EXIT_NODE"
          fi
          ;;
      3)  # Reapply exit node
          if [[ -n "$DESIRED_EXIT_NODE" ]]; then
              sudo tailscale set --exit-node="$DESIRED_EXIT_NODE"
          fi
          ;;
  esac

''
