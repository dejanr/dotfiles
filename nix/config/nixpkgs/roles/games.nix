{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
    wineWowPackages.stable
    winetricks
    dxvk
    d9vk
  ];
}
