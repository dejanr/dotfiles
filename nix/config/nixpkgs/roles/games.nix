{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
    wine
    winetricks
    dxvk
    pyfa
  ];
}
