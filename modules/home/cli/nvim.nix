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

        # treesitter
        pkgs.vimPlugins.nvim-treesitter-parsers.bash
        pkgs.vimPlugins.nvim-treesitter-parsers.csv
        pkgs.vimPlugins.nvim-treesitter-parsers.go
        pkgs.vimPlugins.nvim-treesitter-parsers.zig
        pkgs.vimPlugins.nvim-treesitter-parsers.graphql
        pkgs.vimPlugins.nvim-treesitter-parsers.html
        pkgs.vimPlugins.nvim-treesitter-parsers.javascript
        pkgs.vimPlugins.nvim-treesitter-parsers.json
        pkgs.vimPlugins.nvim-treesitter-parsers.latex
        pkgs.vimPlugins.nvim-treesitter-parsers.lua
        pkgs.vimPlugins.nvim-treesitter-parsers.make
        pkgs.vimPlugins.nvim-treesitter-parsers.gleam
        pkgs.vimPlugins.nvim-treesitter-parsers.html
        pkgs.vimPlugins.nvim-treesitter-parsers.markdown
        pkgs.vimPlugins.nvim-treesitter-parsers.markdown_inline
        pkgs.vimPlugins.nvim-treesitter-parsers.mermaid
        pkgs.vimPlugins.nvim-treesitter-parsers.nix
        pkgs.vimPlugins.nvim-treesitter-parsers.python
        pkgs.vimPlugins.nvim-treesitter-parsers.terraform
        pkgs.vimPlugins.nvim-treesitter-parsers.toml
        pkgs.vimPlugins.nvim-treesitter-parsers.regex
        pkgs.vimPlugins.nvim-treesitter-parsers.rust
        pkgs.vimPlugins.nvim-treesitter-parsers.sql
        pkgs.vimPlugins.nvim-treesitter-parsers.vim
        pkgs.vimPlugins.nvim-treesitter-parsers.vimdoc
        pkgs.vimPlugins.nvim-treesitter-parsers.tsx
        pkgs.vimPlugins.nvim-treesitter-parsers.typescript
        pkgs.vimPlugins.nvim-treesitter-parsers.toml
        pkgs.vimPlugins.nvim-treesitter-parsers.sway
        pkgs.vimPlugins.nvim-treesitter-parsers.xml
        pkgs.vimPlugins.nvim-treesitter-parsers.yaml
        pkgs.vimPlugins.nvim-treesitter-parsers.css

        pkgs.vimPlugins.nvim-ts-autotag
        pkgs.vimPlugins.nvim-treesitter-context
        pkgs.vimPlugins.nvim-treesitter-textobjects
        pkgs.vimPlugins.nvim-treesitter-textsubjects
        pkgs.vimPlugins.nvim-treesitter-refactor
        pkgs.vimPlugins.nvim-treesitter

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
