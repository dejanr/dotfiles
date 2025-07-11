{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    # Unmigrated roles (still need manual imports)
    ../../modules/system/roles/multimedia.nix
    ../../modules/system/roles/i3.nix
    ../../modules/system/roles/services.nix
    ../../modules/system/roles/games.nix
  ];

  modules.system.roles.desktop.enable = true;
  modules.system.roles.dev.enable = true;
}
