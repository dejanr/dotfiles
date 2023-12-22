-- Keybinds

-- File
vim.keymap.set("n", "<leader>fs", ":w!<CR>", { desc = "Save File" })

-- Winwow movement
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("n", "<leader>q", ":q! <CR>")

vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")
vim.keymap.set("n", ";", ":")

-- Turn off highlight search
vim.keymap.set("n", "<leader>n", ":set invhls<CR>:set hls?<CR>", { desc = "Turn off highlight" })
