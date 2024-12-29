{ ... }: {
  home.file.aerospace = {
    target = ".aerospace.toml";
    text = ''
      enable-normalization-flatten-containers = false
      enable-normalization-opposite-orientation-for-nested-containers = false

      [gaps]
      inner.horizontal = 5
      inner.vertical   = 5
      outer.left       = 5
      outer.bottom     = 5
      outer.top        = 5
      outer.right      = 5

      [mode.main.binding]
      cmd-shift-j = 'focus down'
      cmd-shift-k = 'focus up'
      cmd-shift-l = 'focus right'
      cmd-shift-h = 'focus left'

      cmd-alt-j = 'move down'
      cmd-alt-k = 'move up'
      cmd-alt-l = 'move right'
      cmd-alt-h = 'move left'

      cmd-shift-f = 'fullscreen'
      cmd-shift-m = 'layout floating tiling'

      cmd-1 = 'workspace 1'
      cmd-2 = 'workspace 2'
      cmd-3 = 'workspace 3'
      cmd-4 = 'workspace 4'
      cmd-5 = 'workspace 5'

      cmd-shift-1 = 'move-node-to-workspace 1'
      cmd-shift-2 = 'move-node-to-workspace 2'
      cmd-shift-3 = 'move-node-to-workspace 3'
      cmd-shift-4 = 'move-node-to-workspace 4'
      cmd-shift-5 = 'move-node-to-workspace 5'

      cmd-alt-x = 'reload-config'

      [workspace-to-monitor-force-assignment]
      1 = 'main'
      2 = 'main'
      3 = 'main'
      4 = 'main'
      5 = 'main'

      [[on-window-detected]]
      if.app-name-regex-substring = 'mail'
      run = 'move-node-to-workspace 1'

      [[on-window-detected]]
      if.app-name-regex-substring = 'calendar'
      run = 'move-node-to-workspace 1'

      [[on-window-detected]]
      if.app-name-regex-substring = 'messages'
      run = 'move-node-to-workspace 3'

      [[on-window-detected]]
      if.app-name-regex-substring = 'slack'
      run = 'move-node-to-workspace 5'
    '';
  };
}
