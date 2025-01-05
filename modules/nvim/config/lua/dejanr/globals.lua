vim.cmd("colorscheme nightfox")
vim.cmd('filetype plugin indent on')

-- Autocmds

vim.cmd [[
autocmd FileType nix setlocal shiftwidth=4
]]
