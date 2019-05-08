{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    kbfs
    keybase
    keybase-gui
  ];

  services = {
    keybase = {
      enable = true;
    };

    kbfs = {
      enable = true;
    };
  };
}
