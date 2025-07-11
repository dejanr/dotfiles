{ ... }: {
  home.file.aerospace = {
    target = ".aerospace.toml";
    text = ''
      enable-normalization-flatten-containers = false
      enable-normalization-opposite-orientation-for-nested-containers = false

      [gaps]
      inner.horizontal = 0
      inner.vertical   = 0
      outer.left       = 0
      outer.bottom     = 0
      outer.top        = 0
      outer.right      = 0

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

      cmd-shift-1 = ['move-node-to-workspace 1', 'workspace 1']
      cmd-shift-2 = ['move-node-to-workspace 2', 'workspace 2']
      cmd-shift-3 = ['move-node-to-workspace 3', 'workspace 3']
      cmd-shift-4 = ['move-node-to-workspace 4', 'workspace 4']
      cmd-shift-5 = ['move-node-to-workspace 5', 'workspace 5']

      cmd-alt-x = 'reload-config'

      [workspace-to-monitor-force-assignment]
      1 = 'main'
      2 = 'main'
      3 = 'main'
      4 = 'secondary'
      5 = 'main'

      ### Window Rules
      # Floating apps
      [[on-window-detected]]
      if.app-name-regex-substring = '(Finder|1Password|Google Chrome)'
      run = 'layout floating'

      [[on-window-detected]]
      if.app-name-regex-substring = 'Calendar'
      run = ['layout floating', 'move-node-to-workspace 4']

      [[on-window-detected]]
      if.app-name-regex-substring = 'Simulator'
      run = ['layout floating']

      [[on-window-detected]]
      if.app-name-regex-substring = 'Messages'
      run = ['layout floating', 'move-node-to-workspace 5']

      [[on-window-detected]]
      if.app-name-regex-substring = 'Slack'
      run = ['layout floating', 'move-node-to-workspace 5']
    '';
  };
}
