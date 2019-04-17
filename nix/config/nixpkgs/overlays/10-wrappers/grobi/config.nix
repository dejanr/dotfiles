{ }:
''
rules:
  - name: home

    outputs_connected:
      - HDMI2-GSM-30454-219122
    configure_single: HDMI2
    execute_after:
      - wm-wallpaper

  - name: office
    outputs_connected:
      - eDP1-AUO-9014-0
      - HDMI2-HPN-13411-16843009
      - DP1-HWP-12910-16843009
    configure_row:
      - eDP1
      - HDMI2
      - DP1
    execute_after:
      - xrandr --output HDMI2 --pos 0x0 --output DP1 --pos 1920x0 --output eDP1 --pos 960x1200
      - wm-wallpaper

  - name: office-team-glass-room
    outputs_connected:
      - eDP1-AUO-9014-0
      - DP1-ACR-1040-1361092661

    configure_row:
      - eDP1
      - DP1
    configure_row:
      - eDP1
      - DP1
    execute_after:
      - wm-wallpaper

  - name: mobile
    outputs_disconnected:
      - HDMI2
    configure_single: eDP1
    execute_after:
      - wm-wallpaper

  - name: Fallback
    configure_single: eDP1
    execute_after:
      - wm-wallpaper
''
