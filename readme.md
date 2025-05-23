# Dotfiles

## Secrets

Create new ssh key:

```bash

ssh-keygen -t ed25519 -C dejan@ranisavljevic.com
```

Secrets are managed with sops-nix.
Create age secret key from ssh machine private key:

```bash
mkdir -p ~/.config/sops/age
nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt"
```

To see age public use:

```bash
nix-shell -p ssh-to-age --run "ssh-to-age -i ~/.ssh/id_ed25519.pub"
```

When adding a new key to .sops.yaml, update secrets with:

```bash
sops updatekeys secrets/secrets.yaml
```

## Rebuild

To rebuild and switch to new build:

```bash
sudo nixos-rebuild switch --flake .#
```

## VM Build

We can build and test our nixos environment inside virtual machine.

```bash
nix build  ./#nixosConfigurations.vm.config.system.build.vm
```

Start virtual machine with:

```bash
./result/bin/run-nixos-vm
```

To be able to connect via SSH, we have to forward port 2222 to 22:

```bash
QEMU_NET_OPTS="hostfwd=tcp::2222-:22" ./result/bin/run-nixos-vm
```

Now we can ssh to the vm:

```bash
ssh -p 2222 nixos@localhost
```

## Darwin Rebuild

```bash
nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#
```

## Remote Host Rebuild

To rebuild on remote host use --target-host, e.g:

```bash
nixos-rebuild switch --flake .#m910q1 --target-host 192.168.1.111
```

