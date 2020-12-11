{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
    wine
    winetricks
    dxvk
    pyfa
    libstrangle
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
  ];
}
