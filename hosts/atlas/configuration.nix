{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    # Unmigrated roles (still need manual imports)
    ../../modules/nixos/roles/multimedia.nix
    ../../modules/nixos/roles/i3.nix
    ../../modules/nixos/roles/services.nix
    ../../modules/nixos/roles/games.nix
  ];

  modules.nixos.roles.desktop.enable = true;
  modules.nixos.roles.dev.enable = true;
}
