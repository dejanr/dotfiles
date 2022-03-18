{}:
''
  rules:
    - name: play
      outputs_connected: [DisplayPort-2, HDMI-A-0]
      configure_row:
        - DisplayPort-0
        - HDMI-A-0
      atomic: true
      execute_after:
        - xrandr --output HDMI-A-0 --off --output DisplayPort-0 --off --output DisplayPort-1 --off --output DisplayPort-2 --mode 3440x1440 --pos 0x0 --rotate normal --primary
        - wm-wallpaper

    - name: work
      outputs_connected: [DisplayPort-2, HDMI-A-0]
      configure_row:
        - DisplayPort-0
        - HDMI-A-0
      atomic: true
      execute_after:
        - xrandr --output DisplayPort-0 --off --output DisplayPort-1 --off --output DisplayPort-2 --mode 3440x1440 --pos 0x1080 --rotate normal --primary --output HDMI-A-0 --mode 1920x1080 --pos 760x0 --rotate normal --scale 0.5x0.5
        - wm-wallpaper

    - name: Fallback
      configure_single: DisplayPort-0
      execute_after:
        - wm-wallpaper
''
