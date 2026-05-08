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
    xdg.configFile."hunk/config.toml".text = ''
      theme = "stylix"
    '';

    home.packages = with pkgs; [
      bat
      # broken: devenv
      btop
      ripgrep
      eza
      htop
      pass
      gnupg
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
