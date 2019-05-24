{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neomutt
    isync
    msmtp
    pass
    qtpass
  ];
}
