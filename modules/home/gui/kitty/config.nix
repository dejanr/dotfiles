{ fontSize, colors }:

''
  enable_audio_bell no

  font_family PragmataPro Mono
  font_size ${fontSize}

  #--------------------------------------------------------------------
  # Key bindings 12345 12312321
  #--------------------------------------------------------------------
  # Clipboard
    map super+v             paste_from_clipboard
    map super+c             copy_or_interrupt

  # Screen
    map super+k combine : clear_terminal scroll active : send_text normal,application \x0c

  # Miscellaneous
    map super+equal      increase_font_size
    map super+minus    decrease_font_size
    map super+0 restore_font_size

  # Scrolling
    map super+shift+g       show_last_command_output
    map super+ctrl+p        scroll_to_prompt -1
    map super+ctrl+n        scroll_to_prompt 1

  # Window
    hide_window_decorations titlebar-only
    confirm_os_window_close 0
    macos_quit_when_last_window_closed yes

    enabled_layouts stack
    layout stack
    placement_strategy center
    remember_window_size yes
    draw_minimal_borders yes
    window_margin_width 0
    single_window_margin_width -1
    window_padding_width 0
    single_window_padding_width -1

  #--------------------------------------------------------------------
  # Theme
  #--------------------------------------------------------------------
  # vim:ft=kitty

    ## name:     Catppuccin Kitty Mocha
    ## author:   Catppuccin Org
    ## license:  MIT
    ## upstream: https://github.com/catppuccin/kitty/blob/main/themes/mocha.conf
    ## blurb:    Soothing pastel theme for the high-spirited!



    # The basic colors
    foreground              #cdd6f4
    background              #1e1e2e
    selection_foreground    #1e1e2e
    selection_background    #f5e0dc

    # Cursor colors
    cursor                  #f5e0dc
    cursor_text_color       #1e1e2e

    # URL underline color when hovering with mouse
    url_color               #f5e0dc

    # Kitty window border colors
    active_border_color     #b4befe
    inactive_border_color   #6c7086
    bell_border_color       #f9e2af

    # OS Window titlebar colors
    wayland_titlebar_color system
    macos_titlebar_color system

    # Tab bar colors
    active_tab_foreground   #11111b
    active_tab_background   #cba6f7
    inactive_tab_foreground #cdd6f4
    inactive_tab_background #181825
    tab_bar_background      #11111b

    # Colors for marks (marked text in the terminal)
    mark1_foreground #1e1e2e
    mark1_background #b4befe
    mark2_foreground #1e1e2e
    mark2_background #cba6f7
    mark3_foreground #1e1e2e
    mark3_background #74c7ec

    # The 16 terminal colors

    # black
    color0 #45475a
    color8 #585b70

    # red
    color1 #f38ba8
    color9 #f38ba8

    # green
    color2  #a6e3a1
    color10 #a6e3a1

    # yellow
    color3  #f9e2af
    color11 #f9e2af

    # blue
    color4  #89b4fa
    color12 #89b4fa

    # magenta
    color5  #f5c2e7
    color13 #f5c2e7

    # cyan
    color6  #94e2d5
    color14 #94e2d5

    # white
    color7  #bac2de
    color15 #a6adc8
''
