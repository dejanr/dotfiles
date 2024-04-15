local builtin = require('telescope.builtin')
local telescope = require("telescope")
local actions = require "telescope.actions"

vim.keymap.set('n', '<leader><space>', builtin.find_files, { desc = "Find Files" })
vim.keymap.set('n', '<leader>fg', ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
  { desc = "Find Grep" })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = "Find Buffers" })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = "Find Help Tags" })
vim.keymap.set('n', '<leader>ft', builtin.lsp_document_symbols, { desc = "Find Symbols" })
vim.keymap.set('n', '<leader>fo', builtin.oldfiles, { desc = "Find Old Files" })
vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = "Find Word under Cursor" })
vim.keymap.set('n', '<leader>gc', builtin.git_commits, { desc = "Search Git Commits" })
vim.keymap.set('n', '<leader>gb', builtin.git_bcommits, { desc = "Search Git Commits for Buffer" })

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
      diff_context_lines = vim.o.scrolloff,
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
