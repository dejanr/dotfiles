{ pkgs, ... }:
{
  plugins.telescope = {
    enable = true;

    extensions = {
      fzf-native = {
        enable = true;
        settings = {
          fuzzy = true;
          override_generic_sorter = true;
          override_file_sorter = true;
          case_mode = "smart_case";
        };
      };

      ui-select = {
        enable = true;
      };

      undo = {
        enable = true;
        settings = {
          use_delta = true;
          side_by_side = false;
          vim_diff_opts = {
            ctxlen = 8;
          };
          entry_format = "state #$ID, $STAT, $TIME";
        };
      };
    };

    settings = {
      defaults = {
        previewer = true;
        path_display = [ "truncate" ];
        file_ignore_patterns = [
          "^.git/"
          "node_modules"
        ];
      };

      pickers = {
        find_files = {
          find_command = [
            "rg"
            "--files"
            "--hidden"
            "--glob"
            "!**/.git/*"
          ];
        };
      };
    };

    keymaps = {
      "<leader><space>" = {
        action = "find_files";
        options = {
          desc = "Find Files";
        };
      };
      "<leader>fb" = {
        action = "buffers";
        options = {
          desc = "Find Buffer";
        };
      };
      "<leader>fh" = {
        action = "help_tags";
        options = {
          desc = "Find Help Tag";
        };
      };
      "<leader>ft" = {
        action = "lsp_document_symbols";
        options = {
          desc = "Find LSP Symbol";
        };
      };
      "<leader>fc" = {
        action = "git_bcommits";
        options = {
          desc = "Find Buffer Commit";
        };
      };
    };
  };

  extraPlugins = with pkgs.vimPlugins; [
    telescope-live-grep-args-nvim
    telescope-media-files-nvim
  ];

  extraConfigLua = ''
    local telescope = require('telescope')
    local actions = require('telescope.actions')

    local select_one_or_multi = function(prompt_bufnr)
      local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
      local multi = picker:get_multi_selection()
      if not vim.tbl_isempty(multi) then
        require('telescope.actions').close(prompt_bufnr)
        for _, j in pairs(multi) do
          if j.path ~= nil then
            vim.cmd(string.format("%s %s", "edit", j.path))
          end
        end
      else
        require('telescope.actions').select_default(prompt_bufnr)
      end
    end

    telescope.setup({
      defaults = {
        mappings = {
          n = {
            ["<C-q>"] = actions.smart_send_to_loclist + actions.open_loclist,
          },
          i = {
            ["<esc>"] = actions.close,
            ["<C-j>"] = actions.cycle_history_next,
            ["<C-k>"] = actions.cycle_history_prev,
            ["<CR>"] = select_one_or_multi,
            ["<C-q>"] = actions.smart_send_to_loclist + actions.open_loclist,
            ["<C-S-d>"] = actions.delete_buffer,
          }
        },
      },
      extensions = {
        media_files = {
          filetypes = { "png", "webp", "jpg", "jpeg", "pdf" },
          find_cmd = "rg"
        }
      }
    })

    telescope.load_extension('live_grep_args')
    telescope.load_extension('media_files')

    vim.keymap.set('n', '<leader>fg', function()
      telescope.extensions.live_grep_args.live_grep_args()
    end, { desc = 'Find Grep' })
  '';
}
