# Dotfiles

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
