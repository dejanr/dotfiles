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
  # Nightfox colors for Kitty
  ## name: nightfox
  ## upstream: https://github.com/edeneast/nightfox.nvim/raw/main/extra/nightfox/nightfox_kitty.conf

    background #1c1c1c
    foreground #cdcecf
    selection_background #2b3b51
    selection_foreground #cdcecf
    cursor_text_color #192330
    url_color #81b29a

  # Cursor
  # uncomment for reverse background
  # cursor none
    cursor #cdcecf

  # Border
    active_border_color #719cd6
    inactive_border_color #39506d
    bell_border_color #f4a261

  # Tabs
    active_tab_background #719cd6
    active_tab_foreground #131a24
    inactive_tab_background #2b3b51
    inactive_tab_foreground #738091

  # normal
    color0 #393b44
    color1 #c94f6d
    color2 #81b29a
    color3 #dbc074
    color4 #719cd6
    color5 #9d79d6
    color6 #63cdcf
    color7 #dfdfe0

  # bright
    color8 #575860
    color9 #d16983
    color10 #8ebaa4
    color11 #e0c989
    color12 #86abdc
    color13 #baa1e2
    color14 #7ad5d6
    color15 #e4e4e5

  # extended colors
    color16 #f4a261
    color17 #d67ad2
''
