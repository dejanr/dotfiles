{ config, pkgs, lib, ... }:

with lib;

let cfg = config.modules.nvim;
in {
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
          config = "";
        }
        {
          plugin = plenary-nvim;
          type = "lua";
          config = "";
        }
        {
          plugin = nightfox-nvim;
          type = "lua";
          lazy = true;
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
        popup-nvim
        telescope-nvim
        telescope-fzf-native-nvim
        telescope-undo-nvim
        telescope-ui-select-nvim
        telescope-live-grep-args-nvim
        telescope-media-files-nvim

        # lsp
        {
          plugin = nvim-lspconfig;
          type = "lua";
          config = ''
            local lspconfig = require('lspconfig')
            lspconfig.lua_ls.setup{
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
            lspconfig.ts_ls.setup {
              on_attach = on_attach,
              root_dir = lspconfig.util.root_pattern("package.json"),
              single_file_support = false
            }
            lspconfig.denols.setup({
              root_dir = lspconfig.util.root_pattern("deno.json"),
              init_options = {
                lint = true,
                unstable = true,
                suggest = {
                  imports = {
                    hosts = {
                      ["https://deno.land"] = true,
                      ["https://cdn.nest.land"] = true,
                      ["https://crux.land"] = true,
                    },
                  },
                },
              },
              on_attach = function()
                local active_clients = vim.lsp.get_active_clients()
                for _, client in pairs(active_clients) do
                  -- stop tsserver if denols is already active
                  if client.name == "tsserver" then
                    client.stop()
                  end
                end
              end,
            })
            lspconfig.gleam.setup {}
          '';
        }
        trouble-nvim

        # conform
        {
          plugin = nvim-conform;
          type = "lua";
          config = ''
            require("conform").setup({
                formatters_by_ft = {
                    css = { "prettier" },
                    go = { "gofmt" },
                    html = { "prettier" },
                    javascript = { "prettier" },
                    typescript = { "prettier" },
                    typescriptreact = { "prettier" },
                    json = { "prettier" },
                    lua = { "stylua" },
                    markdown = { "prettier", "markdownlint" },
                    nix = { "nixpkgs-fmt" },
                    python = { "isort", "black" },
                    terraform = { "terraform_fmt" },
                    yaml = { "prettier" }
                },
                format_on_save = {
                    lsp_fallback = true,
                    timeout_ms = 1000,
                },
            })

          '';
        }
        # gen
        {
          plugin = nvim-gen;
          type = "lua";
          config = ''
            local gen = require('gen')

            gen.setup({
                model = "phind-codellama-34b", -- The default model to use.
                host = "localhost", -- The host running the Ollama service.
                port = "11434", -- The port on which the Ollama service is listening.
                quit_map = "q", -- set keymap for close the response window
                retry_map = "<c-r>", -- set keymap to re-send the current prompt
                init = function(options) pcall(io.popen, "ollama serve > /dev/null 2>&1 &") end,
                -- Function to initialize Ollama
                command = function(options)
                    local body = {model = options.model, stream = true}
                    return "curl --silent --no-buffer -X POST http://" .. options.host .. ":" .. options.port .. "/api/chat -d $body"
                end,
                display_mode = "float", -- The display mode. Can be "float" or "split".
                show_prompt = false, -- Shows the prompt submitted to Ollama.
                show_model = false, -- Displays which model you are using at the beginning of your chat session.
                no_auto_close = false, -- Never closes the window automatically.
                debug = false -- Prints errors and the command which is run.
            })
          '';
        }

        # clipboard
        {
          plugin = nvim-neoclip-lua;
          type = "lua";
          config = "require('neoclip').setup()";
        }

        # whitespaces
        {
          plugin = whitespace-nvim;
          type = "lua";
          config = ''
            require("whitespace-nvim").setup {
              highlight = 'DiffDelete',
              ignored_filetypes = { 'TelescopePrompt', 'Trouble', 'help' },
              ignore_terminal = true,
            }
          '';
        }

        # treesitter
        nvim-treesitter-parsers.bash
        nvim-treesitter-parsers.csv
        nvim-treesitter-parsers.go
        nvim-treesitter-parsers.graphql
        nvim-treesitter-parsers.html
        nvim-treesitter-parsers.javascript
        nvim-treesitter-parsers.json
        nvim-treesitter-parsers.latex
        nvim-treesitter-parsers.lua
        nvim-treesitter-parsers.gleam
        nvim-treesitter-parsers.markdown
        nvim-treesitter-parsers.markdown_inline
        nvim-treesitter-parsers.nix
        nvim-treesitter-parsers.python
        nvim-treesitter-parsers.terraform
        nvim-treesitter-parsers.toml
        nvim-treesitter-parsers.org
        nvim-treesitter-parsers.regex
        nvim-treesitter-parsers.rust
        nvim-treesitter-parsers.vim
        nvim-treesitter-parsers.vimdoc
        nvim-treesitter-parsers.tsx
        nvim-treesitter-parsers.typescript
        nvim-treesitter-parsers.xml
        nvim-treesitter-parsers.yaml
        nvim-ts-autotag
        nvim-treesitter-context
        nvim-treesitter-textobjects
        nvim-treesitter-textsubjects
        nvim-treesitter-refactor
        {
          plugin = nvim-treesitter;
          type = "lua";
          config = ''
            local treesitter = require "nvim-treesitter"
            local configs = require "nvim-treesitter.configs"

            configs.setup {
                highlight = {
                    enable = true,
                    disable = { "" },
                    additional_vim_regex_highlighting = true,
                },
                autopairs = {
                    enable = true,
                },
                indent = { enable = true, disable = { "" } },
                autotag = {
                    enable = true,
                },
                textobjects = {
                    select = {
                        enable = true,
                        lookahead = true,
                    }
                },
                textsubjects = {
                    enable = true,
                    prev_selection = ',',
                    keymaps = {
                        ['.'] = {'textsubjects-smart', desc = "Select Containers"},
                        [';'] = {'textsubjects-container-outer', desc = "Select Outside Containers"},
                        ['i;'] = { 'textsubjects-container-inner', desc = "Select Inside Containers" },
                    },
                },
                refactor = {
                    enable = true,
                    highlight_definitions = {
                        enable = true,
                        clear_on_cursor_move = true,
                    },
                    smart_rename = {
                        enable = true,
                        keymaps = {
                        smart_rename = false,
                        }
                    }
                },
            }
          '';
        }
        # git
        {
          plugin = git-blame-nvim;
          type = "lua";
          config = ''
            require('gitblame').setup {
              enabled = true,
              delay = 3000,
              use_blame_commit_file_urls = true,
            }
          '';
        }
      ];

      extraPackages = with pkgs; [
        ripgrep
        nodejs
        # Language Servers
        nodePackages.bash-language-server # Bash
        nodePackages.typescript-language-server # TS
        nodePackages.vscode-langservers-extracted # Web (ESLint, HTML, CSS, JSON)
        nixpkgs-fmt # Nix
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
