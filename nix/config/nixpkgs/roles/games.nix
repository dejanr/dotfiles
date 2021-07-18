{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wine
    winetricks
    cabextract
    dxvk
    pyfa
    libstrangle
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
    legendary-gl # A free and open-source Epic Games Launcher alternative
  ];

  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  programs.steam.remotePlay.openFirewall = true;
  programs.steam.dedicatedServer.openFirewall = true;
}
