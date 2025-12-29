{ pkgs, ... }:
{
  plugins.lsp = {
    enable = true;
    inlayHints = true;

    keymaps = {
      silent = true;
      diagnostic = {
        "<space>d" = "open_float";
        "<space><left>" = "goto_prev";
        "<space><right>" = "goto_next";
        "<leader><ctrl>q" = "setloclist";
      };
      lspBuf = {
        "K" = "hover";
        "gra" = "code_action";
        "grn" = "rename";
        "grr" = "references";
        "grd" = "definition";
        "grD" = "declaration";
        "gri" = "implementation";
        "grt" = "type_definition";
        "grf" = "format";
        "grk" = "signature_help";
        "grs" = "document_symbol";
        "grwa" = "add_workspace_folder";
        "grwr" = "remove_workspace_folder";
      };
    };

    servers = {
      lua_ls = {
        enable = true;
        settings = {
          Lua = {
            runtime = {
              version = "LuaJIT";
            };
            workspace = {
              checkThirdParty = false;
              library = [
                "\${3rd}/luv/library"
              ];
            };
            telemetry = {
              enable = false;
            };
          };
        };
      };

      bashls = {
        enable = true;
      };

      ts_ls = {
        enable = true;
        extraOptions = {
          root_dir = ''
            function(fname)
              local util = require('lspconfig.util')
              local monorepo = require('lsp.monorepo')
              local bufnr = vim.fn.bufnr(fname)
              return monorepo.find_monorepo_root(
                bufnr,
                { "package.json", "tsconfig.json", ".git" },
                { "frontend", "backend", "packages", "apps", "services" }
              )
            end
          '';
          init_options = {
            plugins = [];
            preferences = {
              includeInlayParameterNameHints = "all";
              includeInlayParameterNameHintsWhenArgumentMatchesName = true;
              includeInlayFunctionParameterTypeHints = true;
              includeInlayVariableTypeHints = true;
              includeInlayPropertyDeclarationTypeHints = true;
              includeInlayFunctionLikeReturnTypeHints = true;
              includeInlayEnumMemberValueHints = true;
              importModuleSpecifierPreference = "non-relative";
            };
          };
        };
        filetypes = [ "typescript" "javascript" "javascriptreact" "typescriptreact" ];
      };

      ruff = {
        enable = true;
      };

      eslint = {
        enable = true;
        extraOptions = {
          root_dir = ''
            function(fname)
              local util = require('lspconfig.util')
              local monorepo = require('lsp.monorepo')
              local bufnr = vim.fn.bufnr(fname)
              return monorepo.find_monorepo_root(
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
            end
          '';
        };
        settings = {
          workingDirectories = {
            mode = "auto";
          };
        };
        onAttach.function = ''
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "EslintFixAll",
          })
        '';
      };

      emmet_ls = {
        enable = true;
      };

      gopls = {
        enable = true;
        settings = {
          gopls = {
            gofumpt = true;
            env = {
              GOFLAGS = "-tags=windows,linux,darwin,test,unittest";
            };
            codelenses = {
              gc_details = false;
              generate = true;
              regenerate_cgo = true;
              run_govulncheck = true;
              test = true;
              tidy = true;
              upgrade_dependency = true;
              vendor = true;
            };
            hints = {
              assignVariableTypes = true;
              compositeLiteralFields = true;
              compositeLiteralTypes = true;
              constantValues = true;
              functionTypeParameters = true;
              parameterNames = true;
              rangeVariableTypes = true;
            };
            analyses = {
              fieldalignment = true;
              nilness = true;
              unusedparams = true;
              unusedwrite = true;
              useany = true;
            };
            usePlaceholders = true;
            completeUnimported = true;
            staticcheck = true;
            directoryFilters = [ "-.git" "-node_modules" ];
            semanticTokens = true;
          };
        };
      };

      cssls = {
        enable = true;
        settings = {
          css = {
            lint = {
              unknownAtRules = "ignore";
            };
          };
        };
      };

      tailwindcss = {
        enable = true;
        settings = {
          tailwindCSS = {
            classAttributes = [ "class" "className" "class:list" "classList" "ngClass" ];
            includeLanguages = {
              eelixir = "html-eex";
              eruby = "erb";
              htmlangular = "html";
              templ = "html";
            };
            lint = {
              cssConflict = "warning";
              invalidApply = "error";
              invalidConfigPath = "error";
              invalidScreen = "error";
              invalidTailwindDirective = "error";
              invalidVariant = "error";
              recommendedVariantOrder = "warning";
            };
            validate = true;
          };
        };
      };

      jsonls = {
        enable = true;
        filetypes = [ "json" "jsonc" ];
        extraOptions = {
          init_options = {
            provideFormatter = true;
          };
        };
      };

      html = {
        enable = true;
      };

      ltex = {
        enable = true;
        filetypes = [ "bibtex" "markdown" "latex" "tex" ];
      };

      nixd = {
        enable = true;
        settings = {
          nixd = {
            formatting = {
              command = [ "nixfmt" ];
            };
          };
        };
      };

      texlab = {
        enable = true;
        settings = {
          texlab = {
            auxDirectory = ".";
            bibtexFormatter = "texlab";
            build = {
              args = [ "-pdf" "-interaction=nonstopmode" "-synctex=1" "%f" ];
              executable = "latexmk";
              forwardSearchAfter = false;
              onSave = false;
            };
            chktex = {
              onEdit = false;
              onOpenAndSave = false;
            };
            diagnosticsDelay = 300;
            formatterLineLength = 100;
            latexFormatter = "latexindent";
            latexindent = {
              modifyLineBreaks = false;
            };
          };
        };
      };

      intelephense = {
        enable = true;
        package = null;
      };

      jdtls = {
        enable = true;
      };

      yamlls = {
        enable = true;
        settings = {
          yaml = {
            validate = true;
            hover = true;
            completion = true;
            format = {
              enable = true;
              singleQuote = true;
              bracketSpacing = true;
            };
            editor = {
              tabSize = 2;
            };
            schemaStore = {
              enable = true;
            };
          };
        };
      };

      rust_analyzer = {
        enable = true;
        installCargo = true;
        installRustc = true;
      };

      tinymist = {
        enable = true;
        settings = {
          formatterMode = "typstyle";
        };
      };
    };
  };

  plugins.navic = {
    enable = true;
    settings = {
      lsp = {
        auto_attach = true;
      };
    };
  };

  extraConfigLua = ''
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

    local lspconfig = require('lspconfig')
    for _, server in pairs(lspconfig.util.available_servers()) do
      local config = lspconfig[server]
      if config then
        config.handlers = vim.tbl_extend("force", config.handlers or {}, handlers)
      end
    end

    vim.diagnostic.config({
      virtual_text = {
        prefix = "",
      },
      jump = {
        float = true,
      },
      float = { border = "single" },
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = " ",
          [vim.diagnostic.severity.WARN] = " ",
          [vim.diagnostic.severity.HINT] = "󰌶 ",
          [vim.diagnostic.severity.INFO] = " ",
        },
        numhl = {
          [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
          [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
          [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
          [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
        },
      },
    })

    vim.keymap.set("n", "<Space>ih", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end, { desc = "Toggle Inlay Hints" })

    vim.keymap.set("n", "grwl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, { desc = "LSP List Workspace Folder" })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client.server_capabilities.documentSymbolProvider then
          vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
        end
      end,
    })
  '';

  extraFiles = {
    "lua/lsp/monorepo.lua".source = ../../lua/lsp/monorepo.lua;
  };
}
