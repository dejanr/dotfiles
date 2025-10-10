{
  pkgs,
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.home.cli.nvim;
in
{
  options.modules.home.cli.nvim = {
    enable = mkEnableOption "nvim";
  };

  config = mkIf cfg.enable {
    home.sessionPath = [
      "$HOME/.local/share/nvim/mason/bin"
    ];

    home.packages = with pkgs; [
      ripgrep
      tree-sitter
      lua-language-server
      rust-analyzer-unwrapped
      black # python code formatter
      nixd # nix lsp
      nixfmt-rfc-style # nix formatter used by nixd -> nixfmt
    ];

    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      plugins = [
        pkgs.vimPlugins.vim-nix
        pkgs.vimPlugins.plenary-nvim
        pkgs.vimPlugins.nvim-treesitter.withAllGrammars
        pkgs.vimPlugins.nvim-ts-autotag
        pkgs.vimPlugins.blink-cmp-git
        pkgs.vimPlugins.LazyVim
      ];

      extraPackages = with pkgs; [
        ripgrep
        nodejs_22

        # Language Servers
        nodePackages.bash-language-server # Bash
        nodePackages.typescript-language-server # TS
        nodePackages.vscode-langservers-extracted # Web (ESLint, HTML, CSS, JSON)
        nixpkgs-fmt # Nix
        lua-language-server # Lua
        tailwindcss-language-server # Tailwind CSS Language Server
        gopls # Official language server for the Go language
        emmet-ls
      ];
    };

    home.file."./.config/nvim/" = {
      source = ./nvim/config;
      recursive = true;
    };

    home.file."./.config/nvim/init.lua".text = ''
      require("config.lazy")
      require('dejanr.globals')
      require('dejanr.options')
      require('dejanr.keymaps')
    '';
  };
}
