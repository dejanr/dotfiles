return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufReadPost", "BufNewFile" },
	depedencies = { "saghen/blink.cmp" },
	config = function()
		-- ╭───────╮
		-- │ MASON │
		-- ╰───────╯
		require("mason").setup({
			ui = {
				icons = {
					package_installed = " ",
					package_pending = " ",
					package_uninstalled = " ",
				},
				border = "single",
				height = 0.8,
			},
		})

		-- ╭─────────────────╮
		-- │ MASON LSPCONFIG │
		-- ╰─────────────────╯
		require("mason-lspconfig").setup({
			ensure_installed = {
				"bashls",
				"cssls",
				"emmet_ls",
				"eslint",
				"html",
				"intelephense",
				"jdtls",
				"jsonls",
				"ltex",
				"lua_ls",
				"ruff",
				"rust_analyzer",
				"texlab",
				"ts_ls",
				"yamlls",
			},
		})

		-- ╭──────────────────────╮
		-- │ CMP LSP CAPABILITIES │
		-- ╰──────────────────────╯
		local capabilities = require("blink.cmp").get_lsp_capabilities()

		-- ╭───────────────────╮
		-- │ WINBAR WITH NAVIC │
		-- ╰───────────────────╯
		local navic = require("nvim-navic")

		-- ╭──────────────────────────╮
		-- │ MONOREPO ROOT DIR HELPER │
		-- ╰──────────────────────────╯
		local function find_monorepo_root(bufnr, markers, workspace_dirs)
			-- Try to find closest marker file first
			local closest_root = vim.fs.root(bufnr, markers)
			if not closest_root then
				return nil
			end

			-- Check if we're inside a monorepo workspace
			for _, workspace in ipairs(workspace_dirs or {}) do
				local workspace_pattern = workspace .. "/"
				local bufname = vim.api.nvim_buf_get_name(bufnr)
				if bufname:match(workspace_pattern) then
					-- Find the workspace root that contains the marker
					local workspace_root = vim.fs.root(bufnr, function(name, path)
						return vim.fn.isdirectory(path .. "/" .. workspace) == 1
							and vim.fn.filereadable(path .. "/" .. workspace .. "/" .. markers[1]) == 1
					end)
					if workspace_root then
						return workspace_root .. "/" .. workspace
					end
				end
			end

			return closest_root
		end

		-- ╭─────────────────────────────────────────────────────────╮
		-- │                   DIAGNOSTIC KAYMAPS                    │
		-- ╰─────────────────────────────────────────────────────────╯
		local opts = function(desc)
			return { noremap = true, silent = true, desc = desc }
		end

		vim.keymap.set("n", "<space>d", vim.diagnostic.open_float, opts("Open Diagnostic Window"))
		vim.keymap.set("n", "<space><left>", function()
			vim.diagnostic.jump({ count = -vim.v.count1 })
		end, opts("Previous Diagnostic"))
		vim.keymap.set("n", "<space><right>", function()
			vim.diagnostic.jump({ count = vim.v.count1 })
		end, opts("Next Diagnostic"))
		vim.keymap.set("n", "<leader><ctrl>q", vim.diagnostic.setloclist, opts("Send Diagnostic to Locallist"))

		-- ╭───────────────────────╮
		-- │ LSPATTACH AUTOCOMMAND │
		-- ╰───────────────────────╯
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

				-- ╭─────────╮
				-- │ KEYMAPS │
				-- ╰─────────╯
				local bufopts = function(desc)
					return { buffer = ev.buf, desc = desc }
				end
				-- All lsp keymaps starts with gr expept K.
				-- Default lsp keymaps. Setting the keymaps again, only to change the description.
				vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts("Hover"))
				vim.keymap.set({ "n", "v" }, "gra", vim.lsp.buf.code_action, bufopts("LSP Code Action"))
				vim.keymap.set("n", "grn", vim.lsp.buf.rename, bufopts("LSP Rename"))
				vim.keymap.set("n", "grr", vim.lsp.buf.references, bufopts("LSP References"))
				-- Custom lsp keymaps.
				vim.keymap.set("n", "grd", vim.lsp.buf.definition, bufopts("LSP Go to Definition"))
				vim.keymap.set("n", "grD", vim.lsp.buf.declaration, bufopts("LSP Go to Declaration"))
				vim.keymap.set("n", "gri", vim.lsp.buf.implementation, bufopts("LSP Go to Implementation"))
				vim.keymap.set("n", "grf", function()
					vim.lsp.buf.format({ async = true })
				end, bufopts("LSP Formatting"))
				vim.keymap.set("n", "grk", vim.lsp.buf.signature_help, bufopts("LSP Singature Help"))
				vim.keymap.set("n", "grs", vim.lsp.buf.document_symbol, bufopts("LSP Document Symbols"))
				vim.keymap.set("n", "grt", vim.lsp.buf.type_definition, bufopts("LSP Type Definition"))
				vim.keymap.set("n", "grwa", vim.lsp.buf.add_workspace_folder, bufopts("LSP Add Workspace Folder"))
				vim.keymap.set("n", "grwr", vim.lsp.buf.remove_workspace_folder, bufopts("LSP Remove Workspace Folder"))
				vim.keymap.set("n", "grwl", function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end, bufopts("LSP List Workspace Folder"))

				-- Get client
				local client = vim.lsp.get_client_by_id(ev.data.client_id)

				-- ╭─────────────╮
				-- │ INLAY HINTS │
				-- ╰─────────────╯
				if client.server_capabilities.inlayHintProvider then
					vim.lsp.inlay_hint.enable(true)
				else
					vim.lsp.inlay_hint.enable(false)
				end

				-- ╭────────────╮
				-- │ NVIM-NAVIC │
				-- ╰────────────╯
				if client.server_capabilities.documentSymbolProvider then
					vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
					navic.attach(client, ev.buf)
				end
			end,
		})

		-- ╭────────────────────╮
		-- │ TOGGLE INLAY HINTS │
		-- ╰────────────────────╯
		if vim.lsp.inlay_hint then
			vim.keymap.set("n", "<Space>ih", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
			end, { desc = "Toggle Inlay Hints" })
		end

		-- ╭─────────────╮
		-- │ LSP BORDERS │
		-- ╰─────────────╯
		local border = {
			{ "┌", "FloatBorder" },
			{ "─", "FloatBorder" },
			{ "┐", "FloatBorder" },
			{ "│", "FloatBorder" },
			{ "┘", "FloatBorder" },
			{ "─", "FloatBorder" },
			{ "└", "FloatBorder" },
			{ "│", "FloatBorder" },
		}

		local handlers = {
			["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border }),
			["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = border }),
		}

		-- ╭─────────────────────────────────────────╮
		-- │ DISABLE LSP INLINE DIAGNOSTICS MESSAGES │
		-- ╰─────────────────────────────────────────╯
		-- vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
		--     virtual_text = false,
		-- })

		-- ╭───────────────────╮
		-- │ DIAGNOSTIC CONFIG │
		-- ╰───────────────────╯
		vim.diagnostic.config({
			virtual_text = {
				prefix = "", -- Could be '●', '▎', │, 'x', '■', , 
			},
			jump = {
				float = true,
			},
			float = { border = "single" },
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.HINT] = "󰌶 ",
					[vim.diagnostic.severity.INFO] = " ",
				},
				numhl = {
					[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
					[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
					[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
					[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
				},
			},
		})

		--  ╭──────────────────────────────────────────────────────────╮
		--  │                         SERVERS                          │
		--  ╰──────────────────────────────────────────────────────────╯

		-- ╭────────────╮
		-- │ LUA SERVER │
		-- ╰────────────╯
		local runtime_path = vim.split(package.path, ";")
		table.insert(runtime_path, "lua/?.lua")
		table.insert(runtime_path, "lua/?/init.lua")
		vim.lsp.config('lua_ls', {
			capabilities = capabilities,
			handlers = handlers,
			on_init = function(client)
				local path = client.workspace_folders[1].name
				if vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc") then
					return
				end

				client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
					runtime = {
						-- Tell the language server which version of Lua you're using
						-- (most likely LuaJIT in the case of Neovim)
						version = "LuaJIT",
					},
					-- Make the server aware of Neovim runtime files
					workspace = {
						checkThirdParty = false,
						library = {
							vim.env.VIMRUNTIME,
							-- Depending on the usage, you might want to add additional paths here.
							-- "${3rd}/luv/library"
							-- "${3rd}/busted/library",
						},
						-- or pull in all of 'runtimepath'. NOTE: this is a lot slower
						-- library = vim.api.nvim_get_runtime_file("", true)
					},
				})
				client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
			end,
			settings = {
				Lua = {},
			},
		})
		vim.lsp.enable('lua_ls')

		-- ╭─────────────╮
		-- │ BASH SERVER │
		-- ╰─────────────╯
		vim.lsp.config('bashls', {
			capabilities = capabilities,
			handlers = handlers,
		})
		vim.lsp.enable('bashls')

		-- ╭───────────────────╮
		-- │ JAVASCRIPT SERVER │
		-- ╰───────────────────╯
		vim.lsp.config('ts_ls', {
			capabilities = capabilities,
			handlers = handlers,
			root_dir = function(bufnr, on_dir)
				local root = find_monorepo_root(
					bufnr,
					{ "package.json", "tsconfig.json", ".git" },
					{ "frontend", "backend", "packages", "apps", "services" }
				)
				on_dir(root)
			end,
			init_options = {
				plugins = {},
				preferences = {
					includeInlayParameterNameHints = "all",
					includeInlayParameterNameHintsWhenArgumentMatchesName = true,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayVariableTypeHints = true,
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayEnumMemberValueHints = true,
					importModuleSpecifierPreference = "non-relative",
				},
			},
			filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact" },
		})
		vim.lsp.enable('ts_ls')

		-- ╭───────────────╮
		-- │ PYTHON SERVER │
		-- ╰───────────────╯
		vim.lsp.config('ruff', {
			capabilities = capabilities,
			handlers = handlers,
		})
		vim.lsp.enable('ruff')

		-- ╭──────────────╮
		-- │ ESLINT SERVER│
		-- ╰──────────────╯
		vim.lsp.config('eslint', {
			capabilities = capabilities,
			handlers = handlers,
			root_dir = function(bufnr, on_dir)
				local root = find_monorepo_root(
					bufnr,
					{
						"eslint.config.js",
						"eslint.config.mjs",
						"eslint.config.cjs",
						"eslint.config.ts",
						".eslintrc.js",
						".eslintrc.json",
						"package.json",
						".git"
					},
					{ "frontend", "backend", "packages", "apps", "services" }
				)
				on_dir(root)
			end,
			settings = {
				workingDirectories = { mode = "auto" },
			},
		})
		vim.lsp.enable('eslint')

		-- Auto-fix on save for eslint
		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(args)
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				if client and client.name == "eslint" then
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = args.buf,
						command = "EslintFixAll",
					})
				end
			end,
		})

		-- ╭──────────────╮
		-- │ EMMET SERVER │
		-- ╰──────────────╯
		vim.lsp.config('emmet_ls', {
			capabilities = capabilities,
			handlers = handlers,
		})
		vim.lsp.enable('emmet_ls')

		-- ╭────╮
		-- │ Go │
		-- ╰────╯
		vim.lsp.config('gopls', {
			capabilities = capabilities,
			handlers = handlers,
			settings = {
				gofumpt = true,
				gopls = {
					env = {
						GOFLAGS = "-tags=windows,linux,darwin,test,unittest",
					},
				},
				codelenses = {
					gc_details = false,
					generate = true,
					regenerate_cgo = true,
					run_govulncheck = true,
					test = true,
					tidy = true,
					upgrade_dependency = true,
					vendor = true,
				},
				hints = {
					assignVariableTypes = true,
					compositeLiteralFields = true,
					compositeLiteralTypes = true,
					constantValues = true,
					functionTypeParameters = true,
					parameterNames = true,
					rangeVariableTypes = true,
				},
				analyses = {
					fieldalignment = true,
					nilness = true,
					unusedparams = true,
					unusedwrite = true,
					useany = true,
				},
				usePlaceholders = true,
				completeUnimported = true,
				staticcheck = true,
				directoryFilters = { "-.git", "-node_modules" },
				semanticTokens = true,
			},
		})
		vim.lsp.enable('gopls')

		-- ╭────────────╮
		-- │ CSS SERVER │
		-- ╰────────────╯
		vim.lsp.config('cssls', {
			capabilities = capabilities,
			handlers = handlers,
			settings = {
				css = {
					lint = {
						unknownAtRules = "ignore",
					},
				},
			},
		})
		vim.lsp.enable('cssls')

		-- ╭─────────────────╮
		-- │ TAILWIND SERVER │
		-- ╰─────────────────╯
		vim.lsp.config('tailwindcss', {
			capabilities = capabilities,
			handlers = handlers,
			settings = {
				tailwindCSS = {
					classAttributes = { "class", "className", "class:list", "classList", "ngClass" },
					includeLanguages = {
						eelixir = "html-eex",
						eruby = "erb",
						htmlangular = "html",
						templ = "html",
					},
					lint = {
						cssConflict = "warning",
						invalidApply = "error",
						invalidConfigPath = "error",
						invalidScreen = "error",
						invalidTailwindDirective = "error",
						invalidVariant = "error",
						recommendedVariantOrder = "warning",
					},
					validate = true,
				},
			},
		})
		vim.lsp.enable('tailwindcss')

		-- ╭─────────────╮
		-- │ JSON SERVER │
		-- ╰─────────────╯
		vim.lsp.config('jsonls', {
			capabilities = capabilities,
			handlers = handlers,
			filetypes = { "json", "jsonc" },
			init_options = {
				provideFormatter = true,
			},
		})
		vim.lsp.enable('jsonls')

		-- ╭─────────────╮
		-- │ HTML SERVER │
		-- ╰─────────────╯
		vim.lsp.config('html', {
			capabilities = capabilities,
			handlers = handlers,
			settigns = {
				css = {
					lint = {
						validProperties = {},
					},
				},
			},
		})
		vim.lsp.enable('html')

		-- ╭─────────────╮
		-- │ LTEX SERVER │
		-- ╰─────────────╯
		vim.lsp.config('ltex', {
			capabilities = capabilities,
			handlers = handlers,
			filetypes = { "bibtex", "markdown", "latex", "tex" },
			settings = {
				-- ltex = {
				--     language = 'de-DE',
				-- },
			},
		})
		vim.lsp.enable('ltex')

		vim.lsp.config('nixd', {
			capabilities = capabilities,
			settings = {
				nixd = {
					formatting = {
						command = { "nixfmt" },
					},
				},
			},
		})
		vim.lsp.enable('nixd')

		-- ╭───────────────╮
		-- │ TEXLAB SERVER │
		-- ╰───────────────╯
		vim.lsp.config('texlab', {
			capabilities = capabilities,
			handlers = handlers,
			settings = {
				texlab = {
					auxDirectory = ".",
					bibtexFormatter = "texlab",
					build = {
						args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
						executable = "latexmk",
						forwardSearchAfter = false,
						onSave = false,
					},
					chktex = {
						onEdit = false,
						onOpenAndSave = false,
					},
					diagnosticsDelay = 300,
					formatterLineLength = 100,
					forwardSearch = {
						args = {},
					},
					latexFormatter = "latexindent",
					latexindent = {
						modifyLineBreaks = false,
					},
				},
			},
		})
		vim.lsp.enable('texlab')

		-- ╭────────────╮
		-- │ PHP SERVER │
		-- ╰────────────╯
		vim.lsp.config('intelephense', {
			capabilities = capabilities,
			handlers = handlers,
		})
		vim.lsp.enable('intelephense')

		-- ╭─────────────╮
		-- │ JAVA SERVER │
		-- ╰─────────────╯
		vim.lsp.config('jdtls', {
			capabilities = capabilities,
			handlers = handlers,
		})
		vim.lsp.enable('jdtls')

		-- ╭─────────────╮
		-- │ YAML SERVER │
		-- ╰─────────────╯
		vim.lsp.config('yamlls', {
			capabilities = capabilities,
			handlers = handlers,
			settings = {
				yaml = {
					validate = true,
					hover = true,
					completion = true,
					format = {
						enable = true,
						singleQuote = true,
						bracketSpacing = true,
					},
					editor = {
						tabSize = 2,
					},
					schemaStore = {
						enable = true,
					},
				},
				editor = {
					tabSize = 2,
				},
			},
		})
		vim.lsp.enable('yamlls')

		-- ╭─────────────╮
		-- │ RUST SERVER │
		-- ╰─────────────╯
		vim.lsp.config('rust_analyzer', {
			capabilities = capabilities,
			handlers = handlers,
		})
		vim.lsp.enable('rust_analyzer')

		-- ╭──────────────╮
		-- │ TYPST SERVER │
		-- ╰──────────────╯
		vim.lsp.config('tinymist', {
			capabilities = capabilities,
			handlers = handlers,
			single_file_support = true,
			root_dir = function(bufnr, on_dir)
				on_dir(vim.fn.getcwd())
			end,
			settings = {
				formatterMode = "typstyle",
			},
		})
		vim.lsp.enable('tinymist')
	end,
}
