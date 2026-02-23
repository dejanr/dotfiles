{ colors }:
''
  # Timing
  set -sg repeat-time 600
  set -g display-time 4000

  # Emacs keys in command prompt
  set -g status-keys emacs

  # Clipboard (OSC 52)
  set -g set-clipboard on

  # Allow passthrough for terminal sequences (images, sync rendering)
  set -g allow-passthrough on

  # Extended keys (Ctrl+Shift combos)
  set -g extended-keys on

  # Terminal features with synchronized rendering
  set -as terminal-features ',xterm-ghostty:RGB:clipboard:strikethrough:usstyle:overline:sync'
  set -as terminal-features ',tmux-256color:RGB:clipboard:strikethrough:usstyle:overline:sync'

  # True color and undercurl support
  set -as terminal-overrides ',*:Tc'
  set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
  set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

  # Reduce redraw frequency and flicker
  set -sg status-interval 5
  set -g remain-on-exit off
  
  # Don't wrap searches
  set -g wrap-search off

  # Pane base index (windows use baseIndex from HM)
  set -g pane-base-index 1

  # Reload config
  bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded tmux.conf"

  # Splitting (preserve path)
  bind v split-window -h -p 30 -c "#{pane_current_path}"
  bind s split-window -v -p 30 -c "#{pane_current_path}"
  bind S choose-session

  # Window bindings
  bind C-s last-window

  # demo-it shortcuts
  bind -N "demo-it next" Space run-shell -b 'demo-it next >/dev/null 2>&1'
  bind -N "demo-it prev" BSpace run-shell -b 'demo-it prev >/dev/null 2>&1'

  bind < swap-window -t :-
  bind > swap-window -t :+
  bind -r ( select-window -t :-
  bind -r ) select-window -t :+
  bind Tab next-window
  bind X kill-window
  bind E respawn-window
  unbind ,
  bind R command-prompt "rename-window '%%'"
  unbind .
  bind M command-prompt "move-window '%%'"
  bind -r n previous-window
  bind -r m next-window

  unbind Up
  unbind Right
  unbind Down
  unbind Left

  # Direct pane selection
  bind 1 select-pane -t 1
  bind 2 select-pane -t 2
  bind 3 select-pane -t 3
  bind 4 select-pane -t 4
  bind 5 select-pane -t 5
  bind 6 select-pane -t 6
  bind 7 select-pane -t 7
  bind 8 select-pane -t 8
  bind 9 select-pane -t 9

  # Activity (disabled to reduce flicker)
  setw -g monitor-activity off
  set -g visual-activity off
  set -g visual-bell off
  set -g visual-silence off

  # Autorename
  setw -g automatic-rename on

  # New window
  bind c new-window

  # Copy mode (vi bindings)
  bind -T copy-mode-vi v send-keys -X begin-selection
  bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
  bind -T copy-mode-vi y send-keys -X copy-selection
  bind -T copy-mode-vi H send-keys -X start-of-line
  bind -T copy-mode-vi L send-keys -X end-of-line
  bind -T choice-mode-vi h send-keys -X tree-collapse
  bind -T choice-mode-vi l send-keys -X tree-expand
  bind -T choice-mode-vi H send-keys -X tree-collapse-all
  bind -T choice-mode-vi L send-keys -X tree-expand-all
  bind -T copy-mode-emacs MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel
  bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel

  unbind [
  unbind p
  bind p paste-buffer

  # Terminal keys
  set-window-option -g xterm-keys on

  # Statusline using theme colors
  set -g message-style "fg=#${colors.base00},bg=#${colors.base04}"
  set -g message-command-style "fg=#${colors.base00},bg=#${colors.base04}"
  set -g pane-border-style "fg=#${colors.base03}"
  set -g pane-active-border-style "fg=#${colors.base0D}"
  set -g status "on"
  set -g status-justify "left"
  set -g status-style "fg=#${colors.base04},bg=#${colors.base00}"
  set -g status-left-length "100"
  set -g status-right-length "100"
  set -g status-left-style NONE
  set -g status-right-style NONE
  set -g status-left "#[fg=#${colors.base00},bg=#${colors.base0D},bold] #S "
  set -g status-right ""
  setw -g window-status-activity-style "underscore,fg=#${colors.base04},bg=#${colors.base00}"
  setw -g window-status-separator ""
  setw -g window-status-style "NONE,fg=#${colors.base04},bg=#${colors.base00}"
  setw -g window-status-format "#[default] #I | #W #F "
  setw -g window-status-current-format "#[fg=#${colors.base00},bg=#${colors.base04},bold] #I | #W #F "

  # direnv cleanup
  set-option -g update-environment "DIRENV_DIFF DIRENV_DIR DIRENV_WATCHES"
  set-environment -gu DIRENV_DIFF
  set-environment -gu DIRENV_DIR
  set-environment -gu DIRENV_WATCHES
  set-environment -gu DIRENV_LAYOUT
''
