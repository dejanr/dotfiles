{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
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
}
