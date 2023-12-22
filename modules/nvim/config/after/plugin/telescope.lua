local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader><space>', builtin.find_files, { desc = "Find Files"})
vim.keymap.set('n', '<leader>fg', "<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", { desc = "Live Grep"})
vim.keymap.set('n', '<leader>fc', '<cmd>lua require("telescope.builtin").live_grep({ glob_pattern = "!{spec,test}"})<CR>', { desc = "Live Grep Code"})
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = "Find Buffers"})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = "Find Help Tags"})
vim.keymap.set('n', '<leader>ft', builtin.lsp_document_symbols, { desc = "Find Symbols"})
vim.keymap.set('n', '<leader>fo', builtin.oldfiles, { desc = "Find Old Files"})
vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = "Find Word under Cursor"})
vim.keymap.set('n', '<leader>gc', builtin.git_commits, { desc = "Search Git Commits"})
vim.keymap.set('n', '<leader>gb', builtin.git_bcommits, { desc = "Search Git Commits for Buffer"})

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
        -- `hidden = true` is not supported in text grep commands.
        vimgrep_arguments = {
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
                ["<C-w>"] = actions.send_selected_to_qflist + actions.open_qflist,
            },
            i = {
                ["<esc>"] = actions.close,
                ["<C-j>"] = actions.cycle_history_next,
                ["<C-k>"] = actions.cycle_history_prev,
                ["<CR>"] = select_one_or_multi,
                ["<C-w>"] = actions.send_selected_to_qflist + actions.open_qflist,
                ["<C-S-d>"] = actions.delete_buffer,
            }
        },
    },
    pickers = {
        find_files = {
            -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
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
    }
})

require("telescope").load_extension "neoclip"
require('telescope').load_extension('fzf')
require('telescope').load_extension('ui-select')
require("telescope").load_extension("undo")
require("telescope").load_extension("live_grep_args")
