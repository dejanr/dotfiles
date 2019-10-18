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
      - HDMI2-GSM-30484-304405-LG
    configure_single: HDMI2
    execute_after:
      - xrandr --output eDP1 --off --output HDMI2 --mode 2560x1080 --rate 60 --pos 0x0 --primary
      - wm-wallpaper

  - name: mobile
    outputs_disconnected:
      - HDMI2
    configure_single: eDP1
    execute_after:
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

  - name: office-team-glass-room-mirror
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
      - xrandr --output DP1 --auto --scale-from 2560x1440 --output eDP1
      - wm-wallpaper

  - name: Fallback
    configure_single: eDP1
    execute_after:
      - wm-wallpaper
''
