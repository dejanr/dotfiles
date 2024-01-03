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
        {
            plugin = vim-nix;
            type = "lua";
            config = '''';
        }
        {
            plugin = plenary-nvim;
            type = "lua";
            config = '''';
        }
        {
            plugin = nightfox-nvim;
            type = "lua";
            config = ''
                require('nightfox').setup {
                  options = {
                    transparent = true,
                  },
                }
                vim.cmd("colorscheme nightfox")
            '';
        }
        {
            plugin = lualine-nvim;
            type = "lua";
            config = ''
                require('lualine').setup()
            '';
        }
        {
            plugin = vimux;
            type = "lua";
            config = ''
                vim.g.VimuxOrientation = "h"
                vim.g.VimuxUseNearestPane = 1
            '';
        }

        # nvim tree
        nvim-web-devicons
        circles-nvim
        {
            plugin = nvim-tree-lua;
            type = "lua";
            config = ''
                local circles = require('circles')

                circles.setup({ 
                    icons = { empty = '◯', filled = '●', lsp_prefix = '●' }, 
                    lsp = true
                })

                require('nvim-tree').setup{
                    renderer = {
                        icons = {
                            glyphs = circles.get_nvimtree_glyphs(),
                            show = {
                                file = true,
                                folder = true,
                                folder_arrow = false,
                                git = false
                            }
                        },
                    },
                }
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
            type = "lua";
            config = ''
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
            '';
        }

        # clipboard
        {
            plugin = nvim-neoclip-lua;
            type = "lua";
            config = "require('neoclip').setup()";
        }
      ];

      extraPackages = with pkgs; [
        ripgrep
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
