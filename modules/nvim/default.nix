{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.modules.nvim;
  jabuti-nvim = pkgs.vimUtils.buildVimPlugin {
      name = "jabuti-nvim";
      src = pkgs.fetchFromGitHub {
          owner = "jabuti-theme";
          repo = "jabuti-nvim";
          rev = "17f1b94cbf1871a89cdc264e4a8a2b3b4f7c76d2";
          sha256 = "sha256-iPjwx/rTd98LUPK1MUfqKXZhQ5NmKx/rN8RX1PIuDFA=";
      };
  };
in
{
  options.modules.nvim = { enable = mkEnableOption "nvim"; };

  config = mkIf cfg.enable {

    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      plugins = with pkgs.vimPlugins; [
        vim-nix
        plenary-nvim
        {
            plugin = nightfox-nvim;
            config = ''
              lua << EOF
                require('nightfox').setup {
                  options = {
                    transparent = true,
                  },
                }
                vim.cmd("colorscheme nightfox")
              EOF
            '';
        }
        {
            plugin = lualine-nvim;
            config = ''
              lua << EOF
                require('lualine').setup()
              EOF
            '';
        }

        # nvim tree
        {
            plugin = nvim-tree-lua;
            config = ''
              lua << EOF
                require('nvim-tree').setup{}
              EOF
            '';
        }

        # telescope
        telescope-nvim
        telescope-fzf-native-nvim
        telescope-undo-nvim
        telescope-ui-select-nvim
        telescope-live-grep-args-nvim

        # lsp
        {
            plugin = nvim-lspconfig;
            config = ''
              lua << EOF
                require('lspconfig').lua_ls.setup{
                  settings = {
                    Lua = {
                      diagnostics = { globals = {'vim'} },
                        -- Do not send telemetry data containing a randomized but unique identifier
                      telemetry = {
                        enable = false
                      }
                    }
                  }
                }
                require('lspconfig').rnix.setup{}
                require('lspconfig').tsserver.setup {}
              EOF
            '';
        }

        # clipboard
        {
          plugin = nvim-neoclip-lua;
          config = "lua require('neoclip').setup()";
        }
      ];

      extraPackages = with pkgs; [
        nodejs
        # Language Servers
        nodePackages.bash-language-server # Bash
        nodePackages.typescript-language-server # TS
        nodePackages.vscode-langservers-extracted # Web (ESLint, HTML, CSS, JSON)
        rnix-lsp nixfmt # Nix
        lua-language-server # Lua
      ];

      extraConfig = ''
        :luafile ~/.config/nvim/lua/init.lua
      '';
    };

    xdg.configFile.nvim = {
      source = ./config;
      recursive = true;
    };
  };
}
