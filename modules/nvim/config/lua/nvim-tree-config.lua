require("nvim-tree").setup({
	disable_netrw = true,
	hijack_netrw = true,

	hijack_directories = {
		enable = true,
		auto_open = true,
	},

	open_on_tab = false,
	hijack_cursor = false,
	update_cwd = false,
	diagnostics = {
		enable = true,
		icons = {
			hint = "",
			info = "",
			warning = "",
			error = "",
		},
	},
	update_focused_file = {
		enable = false,
		update_cwd = false,
		ignore_list = {},
	},
	system_open = {
		cmd = nil,
		args = {},
	},
	view = {
		width = 25,
		side = "left",
	},
	actions = {
		open_file = {
			resize_window = true,
		},
	},
})

require("legendary").keymaps({
	{ "<leader>op", ":NvimTreeToggle<cr>", opts = { silent = true }, description = "Nvim Tree: Toggle" },
	{ "<leader>or", ":NvimTreeRefresh<cr>", opts = { silent = true }, description = "Nvim Tree: Refresh" },
	{ "<leader>of", ":NvimTreeFindFile<cr>", opts = { silent = true }, description = "Nvim Tree: Find file" },
})
