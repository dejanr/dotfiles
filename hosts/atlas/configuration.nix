{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/roles/fonts.nix
    ../../modules/system/roles/desktop.nix
    ../../modules/system/roles/multimedia.nix
    ../../modules/system/roles/i3.nix
    ../../modules/system/roles/services.nix
    ../../modules/system/roles/development.nix
    ../../modules/system/roles/games.nix
  ];
}
