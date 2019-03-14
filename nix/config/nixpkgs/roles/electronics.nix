{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    arduino
    minicom
    picocom
    platformio
    fritzing
  ];
}
