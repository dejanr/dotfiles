{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
    steam-run
    minecraft
    wineStaging
    winetricks
  ];

  services = {
    minecraft-server = {
      enable = true;
      eula = true;
      openFirewall = true;
    };
  };
}
