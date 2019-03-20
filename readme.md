## Dotfiles

Reproducible set of dotfiles and packages

### Installation

```
nix-env -f https://github.com/dejanr/dotfiles/archive/master.tar.gz -i --remove-all && dotfiles install
```

### Usage

```
dotfiles [command]
```

- install - install prerequisites and link
- uninstall - unlink and remove configurations
- link - (re-)link dotfiles
- unlink - unlink dotfiles

## NixOS

NixOS configuration could be found under _nix/config/nixpkgs_

### Structure

```
.
├── machines
├── overlays
│   ├── 00-themes
│   ├── 10-wrappers
│   ├── 10-scripts
│   ├── 50-envs
│   └── 90-apps
└── roles
```

- A **machine** has one or more role
- A **overlay** is reusable nix expression
- A **script** is just a bash script packed with nix
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
