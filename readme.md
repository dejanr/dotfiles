## Dotfiles

Reproducible set of dotfiles and packages

### Installation

```
git clone https://github.com/dejanr/dotfiles.git ~/.dotfiles
```

### Usage

This project when built, generates a cli inside ./result/bin/dotfiles.

The easiest way to build it and run it via nix-shell, so lets enter the nix shell:

```
nix-shell
```

We can now link all our files:

```
dotfiles link
```

All possible commands are:

- link - (re-)link dotfiles
- unlink - unlink dotfiles

## NixOS

NixOS configuration could be found under _nix/config/nixpkgs_

### NixOS configuration files could be found under:

```bash
nix/config/nixpkgs/
```


```
.
├── machines
├── overlays
└── roles
```

- A **machine** has one or more role and defines how machine should be configured
- A **overlay** is reusable nix derivation, wrapper or just an script
- A **role** is collection of configuration to fulfill a specific role

### Dotfiles configuration files

It would be ideal that all configuration files are expressed via nix, so that when
we do a rollback our dotfiles are also rollbacked. But being pragmatic its also
fine to have a dotfile as a easy path of configuring and trying something initally.

File organization is inspired from stew, except that files are not prefixed with _._
There are only two rules to it.

- __Files__ like ~/.dotfiles/bash/bashrc is symlinked as follows:
```
ln -s ~/.dotfiles/bash/bashrc ~/.bashrc
```

- __Folders__ are first created and then files of those folders are symlinked.
For example dotfile __~/.dotfiles/newsboat/newsboat/urls__ would be symlinked as follows:

```
mkdir -p ~/.newsboat
ln -s ~/.dotfiles/newsboat/newsboat/urls ~/.newsboat/urls
```

All this is possible to do via dotfiles cli which is built using default.nix and available inside nix shell.

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
