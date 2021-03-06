## Dotfiles

Reproducible set of dotfiles and packages

### Installation

```
git clone https://github.com/dejanr/dotfiles.git ~/.dotfiles
```

### Usage

This project when built, generates a cli inside ./result/bin/dotfiles.

The easiest way to build it and run it is with nix-shell, so lets enter the nix shell:

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

Update nix dependencies:

```
niv update
```

Testing config for home machine:

```
nix-build machines.nix -A home
```

When adding a new machine machines.nix has to be updated and entrypoint
has to be added at nix/config/nixpkgs/$machine/configuration.nix

### NixOS configuration files

They could be found under _~/.dotfiles/nix/config/nixpkgs_

```bash
~/.dotfiles/nix/config/nixpkgs/
├── machines
├── overlays
└── roles
```

- A **machine** has one or more role and defines how machine should be configured
- A **overlay** is reusable nix derivation, app, wrapper or just an nix script
- A **role** is collection of configurations to fulfill a specific role

### dotfiles

It would be ideal that all configuration files are expressed via nix, so that when
we do a rollback our dotfiles are also rollbacked. But being pragmatic we could also
symlink dotfile to our home folder, and use it as is.

File organization is inspired from stew, except that files are not prefixed with _._

- __Files__ like ~/.dotfiles/bash/bashrc are symlinked as follows:
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

## Darwin Setup

For initial setup add nix channels if missing:

```
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
nix-channel --add https://nixos.org/channels/nixos-unstable nixos

nix-channel --update
```

Change to the dotfiles folder:

```
cd ~/.dotfiles
```

Enter nix shell sandbox:

```
nix-shell shell.nix
````

Switch home

```
home-manager switch -f home.nix
```
Add tmux dep

```
nix-env -iA nixpkgs.reattach-to-user-namespace
```
