{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wine
    winetricks
    cabextract
    dxvk
    #vkd3d
    pyfa
    libstrangle
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
    legendary-gl # A free and open-source Epic Games Launcher alternative
    teamspeak_client # voip client
    cemu
    jstest-gtk
    linuxConsoleTools
  ];

  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  programs.steam.remotePlay.openFirewall = true;
  programs.steam.dedicatedServer.openFirewall = true;

  services.joycond.enable = true;
}
