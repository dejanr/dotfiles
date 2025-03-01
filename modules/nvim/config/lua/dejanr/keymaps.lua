local default_opt = { noremap = true, silent = true }

local lsp_format_async = function()
  vim.lsp.buf.format({ async = true })
end

-- Keybinds

-- File
vim.keymap.set("n", "<leader>fs", ":w!<cr>", { desc = "Save File" })
vim.keymap.set("n", "<leader>p", lsp_format_async, { desc = "Format File", noremap = true, silent = true })

-- Show diagnostics in float
vim.keymap.set('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>', default_opt)

-- Previous and Next: Buffer
vim.keymap.set("n", "[b", ":bprevious<cr>", default_opt)
vim.keymap.set("n", "]b", ":bnext<cr>", default_opt)

-- Goto
vim.keymap.set("n", "<leader>gf", "gf", { noremap = true, silent = true, desc = "Go to file" })
vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, { noremap = true, silent = true, desc = "Go to definition" })
vim.keymap.set("n", "<leader>gh", vim.lsp.buf.hover, { noremap = true, silent = true, desc = "Go to hover" })
vim.keymap.set("n", "<leader>gi", vim.lsp.buf.implementation,
  { noremap = true, silent = true, desc = "Go to implementation" })
vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, { noremap = true, silent = true, desc = "Go to references" })
vim.keymap.set("n", "<leader>gs", vim.lsp.buf.signature_help,
  { noremap = true, silent = true, desc = "Go to signature help" })
vim.keymap.set("n", "<leader>gt", vim.lsp.buf.type_definition,
  { noremap = true, silent = true, desc = "Go to type definition" })

-- Winwow movement
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("n", "<leader>q", ":q! <cr>")
vim.keymap.set("n", "<leader>op", ":NvimTreeFocus <cr>")

vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")
vim.keymap.set("n", ";", ":")

-- Previous and Next: Location List
vim.keymap.set("", "<C-n>", ":lnext<cr>")
vim.keymap.set("", "<C-p>", ":lprevious<cr>")

-- Turn off highlight search
vim.keymap.set("n", "<leader>n", ":set invhls<cr>:set hls?<cr>", { desc = "Turn off highlight" })

-- Toggle
vim.cmd([[command! -nargs=0 -bar ToggleLocList lua require('utils').ToggleLocList()]])
vim.cmd([[command! -nargs=0 -bar ToggleQF lua require('utils').ToggleQF()]])
vim.keymap.set("n", "<leader>tl", ":ToggleLocList<cr>", { desc = "Toggle location list" })
vim.keymap.set("n", "<leader>tq", ":ToggleQF<cr>", { desc = "Toggle quickfix list" })
vim.keymap.set("n", "<leader>tp", ":set invpaste<CR>:set paste?<cr>", default_opt)
vim.keymap.set("n", "<leader>ts", ":nohlsearch<cr>", default_opt)

-- Trouble
vim.keymap.set("n", "<leader>xx", function() require("trouble").toggle() end)
vim.keymap.set("n", "<leader>xw", function() require("trouble").toggle("workspace_diagnostics") end)
vim.keymap.set("n", "<leader>xd", function() require("trouble").toggle("document_diagnostics") end)
vim.keymap.set("n", "<leader>xq", function() require("trouble").toggle("quickfix") end)
vim.keymap.set("n", "<leader>xl", function() require("trouble").toggle("loclist") end)
vim.keymap.set("n", "gR", function() require("trouble").toggle("lsp_references") end)
