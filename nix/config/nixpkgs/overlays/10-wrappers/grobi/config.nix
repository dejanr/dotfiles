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
    configure_row:
      - DP1
    execute_after:
      - xrandr --dpi 123 --output eDP1 --off --output HDMI2 --mode 2560x1080 --rate 60 --pos 0x0 --primary
      - echo "Xft.dpi: 123" | xrdb -merge
      - wm-wallpaper

  - name: office-mirror
    outputs_connected:
      - eDP1-AUO-9014-0
      - HDMI2-HPN-13411-16843009
    configure_row:
      - eDP1
      - DP1
    execute_after:
      - xrandr --output HDMI2 --auto --scale-from 2560x1440 --output eDP1
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
