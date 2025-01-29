return {
  'stevearc/conform.nvim',
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        css = { "prettier" },
        go = {"gofumpt", "goimports"},
        html = { "prettier" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        lua = { "stylua" },
        markdown = { "prettier", "markdownlint" },
        nix = { "nixpkgs_fmt" },
        python = { "isort", "black" },
        terraform = { "terraform_fmt" },
        yaml = { "prettier" }
      },
      format_on_save = {
        lsp_fallback = true,
        timeout_ms = 1000,
      },
    })
  end,
}
