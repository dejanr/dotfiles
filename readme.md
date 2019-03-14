## Dotfiles

Reproducible set of dotfiles and packages

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

## NixOS

NixOS configuration could be found under _nix/config/nixpkgs_

Note: Only during the first build of NixOS machine its necessery to tell nixos-rebuild what configuration to use.

### Structure

```
.
├── machines
├── overlays
│   ├── 00-themes
│   ├── 10-wrappers
│   ├── 50-envs
│   └── 90-apps
└── roles
```

- A **machine** has one or more role
- A **overlay** is reusable nix expression
- A **role** is a collection of **packages** and **services**

### Secrets

Secrets are stored in `secrets.nix`, which looks something like this:

```
{
  name = {
    username = "foo";
    password = "bar";
  };
}
```

To use secret you would then just import secrets and access specific field:

```
password = (import ../secrets.nix).name.password;
```
