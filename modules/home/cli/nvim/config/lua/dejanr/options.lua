local o = vim.opt
local aug = vim.api.nvim_create_augroup("dejanr", {})

-- Leader

-- Performance
o.shell = "zsh"
o.shadafile = "NONE"

-- Colors
o.termguicolors = true

-- Undo files
o.undofile = true

-- Indentation
o.tabstop = 2
o.shiftwidth = 2
o.softtabstop = 2
o.shiftround = true
o.expandtab = true
o.autoindent = true
o.smartindent = true
o.scrolloff = 8 -- When the page starts to scroll, keep the cursor 8 lines from the top and 8 lines from the bottom

-- Set clipboard to use system clipboard
o.clipboard = "unnamedplus"

-- Use mouse
o.mouse = "a"

-- Nicer UI settings
o.cursorline = true
o.number = true

-- Get rid of annoying viminfo file
o.viminfo = ""
o.viminfofile = "NONE"

-- Miscellaneous quality of life
o.ignorecase = true
o.ttimeoutlen = 5
o.hidden = true
o.shortmess = "atI"
o.wrap = false
o.backup = false
o.writebackup = false
o.errorbells = false
o.swapfile = false
o.showmode = false
o.laststatus = 3
o.pumheight = 6
o.splitright = true
o.splitbelow = true
o.completeopt = "menuone,noselect"

-- Display sign column always fixed by up to 2 signs
o.signcolumn = "yes:1"

-- auto reload files changed outside of vim
o.autoread = true

vim.api.nvim_create_autocmd("FocusGained", {
	desc = "Reload files from disk when we focus vim",
	pattern = "*",
	command = "if getcmdwintype() == '' | checktime | endif",
	group = aug,
})
vim.api.nvim_create_autocmd("BufEnter", {
	desc = "Every time we enter an unmodified buffer, check if it changed on disk",
	pattern = "*",
	command = "if &buftype == '' && !&modified && expand('%') != '' | exec 'checktime ' . expand('<abuf>') | endif",
	group = aug,
})
