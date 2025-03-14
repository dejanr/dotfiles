{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.packages;
in {
  options.modules.packages = { enable = mkEnableOption "packages"; };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      devenv # Fast, Declarative, Reproducible, and Composable Developer Environments
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
      lua
      # anki-bin
      fd # Simple, fast and user-friendly alternative to find
      rsync
    ];
  };
}
