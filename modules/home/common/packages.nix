{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.home.common.packages;
in
{
  options.modules.home.common.packages = {
    enable = mkEnableOption "home common packages";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # broken: devenv
      btop
      ripgrep
      eza
      htop
      pass
      gnupg
      bat
      unzip
      lowdown
      zk
      age
      libnotify
      git
      python3
      podman
      lua54Packages.lua
      lua54Packages.luarocks
      # anki-bin
      fd # Simple, fast and user-friendly alternative to find
      rsync
    ];
  };
}
