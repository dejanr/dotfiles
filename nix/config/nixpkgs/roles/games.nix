{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
    wineUnstable
    winetricks
    cabextract
    dxvk
    pyfa
    libstrangle
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
  ];
}
