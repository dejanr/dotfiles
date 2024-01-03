vim.g.neovide_cursor_animation_length = 0.00
vim.g.neovide_cursor_trail_size = 0.0
vim.g.neovide_cursor_trail_length = 0.0
vim.g.neovide_cursor_vfx_mode = ""
vim.g.neovide_cursor_antialiasing = true
vim.g.neovide_cursor_vfx_particle_lifetime = 0.0
vim.g.neovide_cursor_animate_in_insert_mode = false
vim.g.neovide_cursor_animate_command_line = false
vim.g.neovide_refresh_rate = 60
vim.g.neovide_refresh_rate_idle = 5

-- can use c-v and c-c
vim.g.neovide_input_use_logo = 1
vim.api.nvim_set_keymap('', '<D-v>', '+p<CR>', { noremap = true, silent = true})
vim.api.nvim_set_keymap('!', '<D-v>', '<C-R>+', { noremap = true, silent = true})
vim.api.nvim_set_keymap('t', '<D-v>', '<C-R>+', { noremap = true, silent = true})
vim.api.nvim_set_keymap('v', '<D-v>', '<C-R>+', { noremap = true, silent = true})

-- Helper function for transparency formatting
local alpha = function()
  return string.format("%x", math.floor((255 * vim.g.transparency) or 0.8))
end

vim.g.neovide_transparency = 0.0
vim.g.transparency = 1.0
vim.g.neovide_background_color = "#0f1117" .. alpha()
