{ colors }:
''
    # Faster typing
    set -sg escape-time 0
    set -sg repeat-time 600

    # increase scrollback buffer size
    set -g history-limit 50000

    # tmux messages are displayed for 4 seconds
    set -g display-time 4000

    # emacs key bindings in tmux command prompt (prefix + :) are better than
    # # vi keys, even for vim users
    set -g status-keys emacs

    # upgrade terminal
    set -g default-terminal "xterm-256color"

    # base index
    set -g base-index 1

    # Reload the config.
    bind r source-file ~/.tmux.conf \; display "Reloaded ~/.tmux.conf"

    # Saner splitting.
    bind v split-window -h -p 30
    bind s split-window -v -p 30
    bind S choose-session

    set -g aggressive-resize on

    # Window bindings
    bind C-s last-window
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
    bind a run tmux-url-select

    # Pane movement
    bind h select-pane -L
    bind j select-pane -D
    bind k select-pane -U
    bind l select-pane -R

    unbind Up
    unbind Right
    unbind Down
    unbind Left

    # DVTM style pane selection
    bind 1 select-pane -t 1
    bind 2 select-pane -t 2
    bind 3 select-pane -t 3
    bind 4 select-pane -t 4
    bind 5 select-pane -t 5
    bind 6 select-pane -t 6
    bind 7 select-pane -t 7
    bind 8 select-pane -t 8
    bind 9 select-pane -t 9

    # Pane resizing
    bind -r H resize-pane -L 5
    bind -r J resize-pane -D 5
    bind -r K resize-pane -U 5
    bind -r L resize-pane -R 5

    # Bad Wolf
    set -g status-style fg=white,bg=colour8
    set -g pane-border-style fg=colour245,bg=black
    set -g pane-active-border-style fg=colour180
    set -g message-style bg=colour221,fg=colour16

    # Custom status bar
    set -g status-left-length 32
    set -g status-right-length 150
    set -g status-interval 5

    set -g status-left '#[fg=colour00,bg=colour254] #S '

    set -g status-right '#[fg=colour254] %R  %d %b #[fg=colour08,bg=colour04] #h '

    set -g window-status-format "#[fg=white,bg=colour234] #I #W "
    set -g window-status-current-format '#[fg=colour07,bg=colour04,noreverse] #I #W '

    # Activity
    setw -g monitor-activity on
    set -g visual-activity off

    # Autorename sanely.
    setw -g automatic-rename on

    # Better name management
    bind c new-window

    # Copy mode
    setw -g mode-keys vi

    run-shell "tmux setenv -g TMUX_VERSION $(tmux -V | cut -c 6-)"

    set -g mouse on

    # New keybindings for vi-mode
    # https://github.com/tmux/tmux/issues/754
    bind -T copy-mode-vi v send-keys -X begin-selection
    bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
    bind -T copy-mode-vi y send-keys -X copy-selection
    bind -T copy-mode-vi H send-keys -X start-of-line
    bind -T copy-mode-vi L send-keys -X end-of-line
    bind -T choice-mode-vi h send-keys -X tree-collapse
    bind -T choice-mode-vi l send-keys -X tree-expand
    bind -T choice-mode-vi H send-keys -X tree-collapse-all
    bind -T choice-mode-vi L send-keys -X tree-expand-all
    bind -T copy-mode-emacs MouseDragEnd1Pane send-keys -X copy-pipe "pbcopy"
    bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe "pbcopy"

    unbind [
    unbind p
    bind p paste-buffer

    # Allow terminal keys in tmux
    set-window-option -g xterm-keys on

    set -g default-shell $SHELL

    # tmuxline
    set -g status-justify "left"
    set -g status "on"
    set -g status-attr "none"
    set -g message-command-bg "colour31"
    set -g status-left-length "100"
    set -g pane-active-border-fg "colour254"
    set -g status-bg "colour234"
    set -g message-command-fg "colour231"
    set -g pane-border-fg "colour240"
    set -g message-bg "colour31"
    set -g status-left-attr "none"
    set -g status-right-attr "none"
    set -g status-right-length "100"
    set -g message-fg "colour231"
    setw -g window-status-fg "colour250"
    setw -g window-status-attr "none"
    setw -g window-status-activity-bg "colour234"
    setw -g window-status-activity-attr "underscore"
    setw -g window-status-activity-fg "colour250"
    setw -g window-status-separator ""
    setw -g window-status-bg "colour234"
    set -g status-left "#[fg=colour16,bg=colour254,bold] #S #[fg=colour254,bg=colour240,nobold,nounderscore,noitalics]#[fg=colour236,bg=colour234,nobold,nounderscore,noitalics]"
    set -g status-right "#[fg=colour232,bg=colour234,nobold,nounderscore,noitalics]#[fg=colour250,bg=colour232] %a #[fg=colour236,bg=colour232,nobold,nounderscore,noitalics]#[fg=colour247,bg=colour236] %R #[fg=colour252,bg=colour236,nobold,nounderscore,noitalics]#[fg=colour235,bg=colour252] #H "
    setw -g window-status-format "#[fg=colour234,bg=colour234,nobold,nounderscore,noitalics]#[default] #I #W #[fg=colour234,bg=colour234,nobold,nounderscore,noitalics]"
    setw -g window-status-current-format "#[fg=colour234,bg=colour31,nobold,nounderscore,noitalics]#[fg=colour231,bg=colour31,bold] #I #W #[fg=colour31,bg=colour234,nobold,nounderscore,noitalics]"

    # direnv cleanup and setup of environment
    set-option -g update-environment "DIRENV_DIFF DIRENV_DIR DIRENV_WATCHES"
    set-environment -gu DIRENV_DIFF
    set-environment -gu DIRENV_DIR
    set-environment -gu DIRENV_WATCHES
    set-environment -gu DIRENV_LAYOUT
''
