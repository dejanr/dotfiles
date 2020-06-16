{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
    wineWowPackages.fonts
    wineWowPackages.staging
    winetricks
    dxvk
  ];
}
