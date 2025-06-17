{}: /* bash */ ''
  #!/usr/bin/env bash

  SERVICE="''${1:-openvpn-office.service}"
  TITLE="''${2:-VPN}"

  DEFAULT_COLOR="#FFFFFF"
  ACTIVE_COLOR="#DBC074"

  if systemctl is-active --quiet "$SERVICE"; then
      echo "$TITLE"
      echo "$TITLE"
      echo "$ACTIVE_COLOR"
  else
      echo "$TITLE"
      echo "$TITLE"
      echo "$DEFAULT_COLOR"
  fi

  case $BLOCK_BUTTON in
      1)  # Left click to toggle
          if systemctl is-active --quiet "$SERVICE"; then
              sudo systemctl stop "$SERVICE"
              pkill -RTMIN+10 i3blocks  # Refresh the block
          else
              sudo systemctl start "$SERVICE"
              pkill -RTMIN+10 i3blocks  # Refresh the block
          fi
          ;;
      3)  # Right click to restart
          sudo systemctl restart "$SERVICE"
          pkill -RTMIN+10 i3blocks  # Refresh the block
          ;;
  esac
''
