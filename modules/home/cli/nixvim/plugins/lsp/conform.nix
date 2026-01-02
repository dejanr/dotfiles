{ pkgs, ... }:
{
  plugins.conform-nvim = {
    enable = true;

    settings = {
      formatters_by_ft = {
        css = [ "prettier" ];
        go = [ "gofumpt" "goimports" ];
        html = [ "prettier" ];
        javascript = [ "prettier" ];
        typescript = [ "prettier" ];
        typescriptreact = [ "prettier" ];
        json = [ "prettier" ];
        lua = [ "stylua" ];
        markdown = [ "prettier" "markdownlint" ];
        nix = [ "nixfmt" ];
        python = [ "isort" "black" ];
        terraform = [ "terraform_fmt" ];
        yaml = [ "prettier" ];
      };

      format_on_save = {
        lsp_fallback = true;
        timeout_ms = 1000;
      };

      formatters = {
        injected = {
          options = {
            ignore_errors = true;
          };
        };
      };
    };
  };

  extraPackages = with pkgs; [
    nodePackages.prettier
    gofumpt
    gotools
    stylua
    nixfmt-rfc-style
    isort
    black
    markdownlint-cli
  ];

  keymaps = [
    {
      mode = "n";
      key = "<leader>p";
      action = "<cmd>lua require('conform').format({ async = true, lsp_fallback = true })<cr>";
      options = {
        desc = "Format File";
        silent = true;
      };
    }
  ];
}
