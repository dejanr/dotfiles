{ colors, fonts, stdenv }:
with colors;

''
  env:
    TERM: xterm-256color

  window:
    dimensions:
      columns: 0
      lines: 0
    padding:
      x: 2
      y: 2
    decorations: none

  scale_with_dpi: true

  tabspaces: 2

  draw_bold_text_with_bright_colors: true

  font:
    normal:
      family: "${fonts.family.mono}"
    bold:
      family: "${fonts.family.mono}"
    italic:
      family: "${fonts.family.mono}"
    size: ${fonts.size.default}
    offset:
      x: 0
      y: 0
    glyph_offset:
      x: 0
      y: 0

  render_timer: false

  colors:
    primary:
      background: '${background}'
      foreground: '${foreground}'
    cursor:
      text: '${foreground}'
      cursor: '${foreground}'
    normal:
      black:   '${color0}'
      red:     '${color1}'
      green:   '${color2}'
      yellow:  '${color3}'
      blue:    '${color4}'
      magenta: '${color5}'
      cyan:    '${color6}'
      white:   '${color7}'
    bright:
      black:   '${color8}'
      red:     '${color9}'
      green:   '${color10}'
      yellow:  '${color11}'
      blue:    '${color12}'
      magenta: '${color13}'
      cyan:    '${color14}'
      white:   '${color15}'
    #dim:
      #black:   '0x333333'
      #red:     '0xf2777a'
      #green:   '0x99cc99'
      #yellow:  '0xffcc66'
      #blue:    '0x6699cc'
      #magenta: '0xcc99cc'
      #cyan:    '0x66cccc'
      #white:   '0xdddddd'

  visual_bell:
    animation: EaseOutExpo
    duration: 0

  background_opacity: 0.9

  mouse_bindings:
    - { mouse: Middle, action: PasteSelection }

  mouse:
    double_click: { threshold: 300 }
    triple_click: { threshold: 300 }
    faux_scrolling_lines: 1
    hide_when_typing: true

  selection:
    semantic_escape_chars: ",│`|:\"' ()[]{}<>"

  dynamic_title: false

  cursor:
    style: Block

  live_config_reload: true

  key_bindings:
    - { key: V,        mods: Control|Shift,    action: Paste               }
    - { key: C,        mods: Control|Shift,    action: Copy                }
''
