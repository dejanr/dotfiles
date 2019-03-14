{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unstable.steam
    unstable.steam-run
    unstable.steamcontroller
    unstable.sc-controller
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
