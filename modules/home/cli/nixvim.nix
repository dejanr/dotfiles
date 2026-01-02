{
  pkgs,
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.home.cli.nixvim;
in
{
  options.modules.home.cli.nixvim = {
    enable = mkEnableOption "nixvim";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      ripgrep
      tree-sitter
      rust-analyzer-unwrapped
      black
      nixd
      nixfmt-rfc-style
      lazygit
    ];

    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      imports = [ ./nixvim ];
    };
  };
}
