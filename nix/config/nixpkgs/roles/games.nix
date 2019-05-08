{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
    steam-run
    unstable.minecraft
    unstable.wineStaging
    unstable.winetricks
  ];

  services = {
    minecraft-server = {
      enable = true;
      eula = true;
      openFirewall = true;
    };
  };
}
