{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.packages;
in {
  options.modules.packages = { enable = mkEnableOption "packages"; };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
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
      lua
      # anki-bin
      fd # Simple, fast and user-friendly alternative to find
      fzf # Command-line fuzzy finder written in Go
    ];
  };
}
