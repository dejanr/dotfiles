# Dotfiles

## Secrets

Create new ssh key:

```bash
ssh-keygen -t ed25519 -C dejan@ranisavljevic.com
```

Secrets are managed with agenix.
Create agenix identity key:

```bash
mkdir -p ~/.ssh
cp ~/.ssh/id_ed25519 ~/.ssh/agenix
```

To see age public key use:

```bash
nix-shell -p ssh-to-age --run "ssh-to-age -i ~/.ssh/id_ed25519.pub"
```

To create or edit a secret:

```bash
cd secrets
agenix -i ~/.ssh/agenix -e secret_name.age
```

When adding a new host key to secrets/secrets.nix, re-encrypt all secrets:

```bash
agenix -r
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

