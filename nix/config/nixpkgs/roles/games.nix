{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
    wine
    winetricks
    dxvk
    d9vk
    lutris
    parsecgaming
  ];
}
