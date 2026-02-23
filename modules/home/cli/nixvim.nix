{
  pkgs,
  config,
  lib,
  inputs,
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
      nixfmt
      lazygit
    ];

    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      _module.args.inputs = inputs;
      imports = [ ./nixvim ];
    };
  };
}
