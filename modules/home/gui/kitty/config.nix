{ fontSize, colors }:

''
  enable_audio_bell no

  font_family PragmataPro Mono
  font_size ${fontSize}

  #--------------------------------------------------------------------
  # Key bindings
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
  # Theme (from stylix)
  #--------------------------------------------------------------------
    foreground              #${colors.base05}
    background              #${colors.base00}
    selection_foreground    #${colors.base00}
    selection_background    #${colors.base05}

    cursor                  #${colors.base05}
    cursor_text_color       #${colors.base00}

    url_color               #${colors.base0D}

    active_border_color     #${colors.base0D}
    inactive_border_color   #${colors.base03}
    bell_border_color       #${colors.base0A}

    wayland_titlebar_color system
    macos_titlebar_color system

    active_tab_foreground   #${colors.base00}
    active_tab_background   #${colors.base0D}
    inactive_tab_foreground #${colors.base05}
    inactive_tab_background #${colors.base01}
    tab_bar_background      #${colors.base00}

    mark1_foreground #${colors.base00}
    mark1_background #${colors.base0D}
    mark2_foreground #${colors.base00}
    mark2_background #${colors.base0E}
    mark3_foreground #${colors.base00}
    mark3_background #${colors.base0C}

    # The 16 terminal colors
    # black
    color0 #${colors.base00}
    color8 #${colors.base03}

    # red
    color1 #${colors.base08}
    color9 #${colors.base08}

    # green
    color2  #${colors.base0B}
    color10 #${colors.base0B}

    # yellow
    color3  #${colors.base0A}
    color11 #${colors.base0A}

    # blue
    color4  #${colors.base0D}
    color12 #${colors.base0D}

    # magenta
    color5  #${colors.base0E}
    color13 #${colors.base0E}

    # cyan
    color6  #${colors.base0C}
    color14 #${colors.base0C}

    # white
    color7  #${colors.base05}
    color15 #${colors.base07}
''
