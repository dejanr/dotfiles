### Installation

```
nix-env -f https://github.com/dejanr/dotfiles/archive/master.tar.gz -i && dotfiles
```

### Usage

```
dotfiles [command]
```

- link - (re-)link dotfiles
- switch (default) - tag, apply configuration.nix, tag working
- update - update channels and switch
- install - install prerequisites and link
- uninstall - unlink and remove configurations
- unlink - unlink dotfiles
