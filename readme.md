## Dotfiles

Reproducible set of dotfiles and packages

### Installation

```
git clone https://github.com/dejanr/dotfiles.git ~/.dotfiles
```

### Usage

```
nix-shell
dotfiles link
```

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
