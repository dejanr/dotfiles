vim.cmd("colorscheme catppuccin")
vim.cmd("filetype plugin indent on")

-- Autocmds

vim.cmd([[
autocmd FileType nix setlocal shiftwidth=4
]])
