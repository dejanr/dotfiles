{ mpsyt, tmux } : ''
#!/usr/bin/env bash

create_music_session() {
  ${tmux} new-session -s music -d
  ${tmux} send-keys ${mpsyt} Enter

  if [ -z "$TMUX" ]; then
    ${tmux} attach -t music
  else
    ${tmux} switch-client -t music
  fi
}

if ${tmux} has-session -t music; then
  ${tmux} attach -t music;
else
  create_music_session;
fi
''
