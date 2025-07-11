return {
  {
    "nvim-telescope/telescope.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-lua/popup.nvim",
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      "debugloop/telescope-undo.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      "nvim-telescope/telescope-media-files.nvim"
    },
    -- stylua: ignore
    keys = {
      {
        "<leader><space>",
        mode = "n",
        function()
          require("telescope.builtin").find_files()
        end,
        desc = "Find Files"
      },
      {
        "<leader>fg",
        mode = "n",
        function()
          require('telescope').extensions.live_grep_args.live_grep_args()
        end,
        desc = "Find Grep"
      },
      {
        "<leader>fg",
        mode = "n",
        function()
          require('telescope').extensions.live_grep_args.live_grep_args()
        end,
        desc = "Find Grep"
      },
      {
        "<leader>fb",
        mode = "n",
        function()
          require('telescope.builtin').buffers()
        end,
        desc = "Find Buffer"
      },
      {
        "<leader>fh",
        mode = "n",
        function()
          require('telescope.builtin').help_tags()
        end,
        desc = "Find Help Tag"
      },
      {
        "<leader>ft",
        mode = "n",
        function()
          require('telescope.builtin').lsp_document_symbols()
        end,
        desc = "Find LSP Symbol"
      },
      {
        "<leader>fc",
        mode = "n",
        function()
          require('telescope.builtin').git_bcommits()
        end,
        desc = "Find Buffer Commit"
      },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require "telescope.actions"

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
          previewer = true,
          -- `hidden = true` is not supported in text grep commands.
          find_command = {
            "rg",
            "-L",
            "--hidden",
            "--glob !**/.git/*",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
          },
          path_display = { "truncate" },
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
        pickers = {
          find_files = {
            find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
          },
        },
        extensions = {
          undo = {
            use_delta = true,
            use_custom_command = nil, -- setting this implies `use_delta = false`. Accepted format is: { "bash", "-c", "echo '$DIFF' | delta" }
            side_by_side = false,
            vim_diff_opts = { ctxlen = 8 },
            entry_format = "state #$ID, $STAT, $TIME",
            mappings = {
              i = {
                ["<C-cr>"] = require("telescope-undo.actions").yank_additions,
                ["<S-cr>"] = require("telescope-undo.actions").yank_deletions,
                ["<cr>"] = require("telescope-undo.actions").restore,
              },
            },
          },
          media_files = {
            filetypes = { "png", "webp", "jpg", "jpeg", "pdf" },
            find_cmd = "rg"
          }
        }
      })

      telescope.load_extension "neoclip"
      telescope.load_extension "live_grep_args"
      telescope.load_extension('fzf')
      telescope.load_extension('ui-select')
      telescope.load_extension("undo")
      telescope.load_extension("live_grep_args")
      telescope.load_extension("media_files")
    end
  }
}
