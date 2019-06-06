{ }:
''
# navigation + keybindings
goto-next-feed no
unbind-key DOWN
bind-key j down
unbind-key UP
bind-key k up

color background white default
color info yellow color237
color listnormal black default bold
color listfocus black yellow
color listnormal_unread cyan default bold
color listfocus_unread black yellow
highlight article "^Feed: .*$" yellow default
highlight article "^Title: .*$" blue default bold
highlight article "^(Author|Link|Date): .*$" green default
highlight article "^\[[0-9]+\]:.*$" green default
highlight article "https?://[^ ]+" red default bold
''
