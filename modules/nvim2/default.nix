{ pkgs, config, lib, ... }:

with lib;

let
  cfg = config.modules.nvim2;
in
{
  options.modules.nvim2 = { enable = mkEnableOption "nvim2"; };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [
      ripgrep
      lua-language-server
      rust-analyzer-unwrapped
      black # python code formatter
    ];

    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      plugins = [
        pkgs.vimPlugins.vim-nix
        pkgs.vimPlugins.plenary-nvim

        # treesitter
        pkgs.vimPlugins.nvim-treesitter-parsers.bash
        pkgs.vimPlugins.nvim-treesitter-parsers.csv
        pkgs.vimPlugins.nvim-treesitter-parsers.go
        pkgs.vimPlugins.nvim-treesitter-parsers.graphql
        pkgs.vimPlugins.nvim-treesitter-parsers.html
        pkgs.vimPlugins.nvim-treesitter-parsers.javascript
        pkgs.vimPlugins.nvim-treesitter-parsers.json
        pkgs.vimPlugins.nvim-treesitter-parsers.latex
        pkgs.vimPlugins.nvim-treesitter-parsers.lua
        pkgs.vimPlugins.nvim-treesitter-parsers.gleam
        pkgs.vimPlugins.nvim-treesitter-parsers.markdown
        pkgs.vimPlugins.nvim-treesitter-parsers.markdown_inline
        pkgs.vimPlugins.nvim-treesitter-parsers.nix
        pkgs.vimPlugins.nvim-treesitter-parsers.python
        pkgs.vimPlugins.nvim-treesitter-parsers.terraform
        pkgs.vimPlugins.nvim-treesitter-parsers.toml
        pkgs.vimPlugins.nvim-treesitter-parsers.org
        pkgs.vimPlugins.nvim-treesitter-parsers.regex
        pkgs.vimPlugins.nvim-treesitter-parsers.rust
        pkgs.vimPlugins.nvim-treesitter-parsers.vim
        pkgs.vimPlugins.nvim-treesitter-parsers.vimdoc
        pkgs.vimPlugins.nvim-treesitter-parsers.tsx
        pkgs.vimPlugins.nvim-treesitter-parsers.typescript
        pkgs.vimPlugins.nvim-treesitter-parsers.xml
        pkgs.vimPlugins.nvim-treesitter-parsers.yaml
        pkgs.vimPlugins.nvim-ts-autotag
        pkgs.vimPlugins.nvim-treesitter-context
        pkgs.vimPlugins.nvim-treesitter-textobjects
        pkgs.vimPlugins.nvim-treesitter-textsubjects
        pkgs.vimPlugins.nvim-treesitter-refactor
        pkgs.vimPlugins.nvim-treesitter
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
      ];
    };

    home.file."./.config/nvim/" = {
      source = ./config;
      recursive = true;
    };

    home.file."./.config/nvim/init.lua".text = ''
      require("config.lazy")

      require('dejanr.globals')
      require('dejanr.options')
      require('dejanr.keymaps')
      -- require('dejanr.prompts')
    '';
  };
}
