{}: /* bash */ ''
  #!/usr/bin/env bash

  EXIT_NODE_NAME_PATTERN="''${1:-pattern}"
  TITLE="''${2:-title}"
  DEFAULT_COLOR="#FFFFFF"
  ACTIVE_COLOR="#DBC074"


  # Get current exit node status (node ID or null)
  CURRENT_EXIT_NODE=$(tailscale status | grep $(sudo tailscale exit-node list | grep Belgrade | awk '{ print $1 }') | grep active)

  # Get desired exit node IP (matching name pattern)
  DESIRED_EXIT_NODE=$(sudo tailscale exit-node list | grep "$EXIT_NODE_NAME_PATTERN" | awk '{ print $1 }' | head -n 1)

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
