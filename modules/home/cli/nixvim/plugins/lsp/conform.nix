{ pkgs, ... }:
{
  plugins.conform-nvim = {
    enable = true;

    settings = {
      formatters_by_ft = {
        css = [ "prettier" ];
        go = [ "treefmt" "gofumpt" "goimports" ];
        html = [ "prettier" ];
        javascript = [ "prettier" ];
        typescript = [ "prettier" ];
        typescriptreact = [ "prettier" ];
        json = [ "prettier" ];
        lua = [ "treefmt" "stylua" ];
        markdown = [ "prettier" "markdownlint" ];
        nix = [ "treefmt" "nixfmt" ];
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

        treefmt = {
          command = "treefmt";
          args = [ "--stdin" "$FILENAME" "--quiet" ];
          stdin = true;
          condition.__raw = ''
            function(_, ctx)
              return vim.fs.find({ "treefmt.toml", ".treefmt.toml" }, {
                upward = true,
                path = ctx.dirname,
              })[1] ~= nil
            end
          '';
        };

        gofumpt.condition.__raw = ''
          function(_, ctx)
            return vim.fs.find({ "treefmt.toml", ".treefmt.toml" }, {
              upward = true,
              path = ctx.dirname,
            })[1] == nil
          end
        '';

        goimports.condition.__raw = ''
          function(_, ctx)
            return vim.fs.find({ "treefmt.toml", ".treefmt.toml" }, {
              upward = true,
              path = ctx.dirname,
            })[1] == nil
          end
        '';

        stylua.condition.__raw = ''
          function(_, ctx)
            return vim.fs.find({ "treefmt.toml", ".treefmt.toml" }, {
              upward = true,
              path = ctx.dirname,
            })[1] == nil
          end
        '';

        nixfmt.condition.__raw = ''
          function(_, ctx)
            return vim.fs.find({ "treefmt.toml", ".treefmt.toml" }, {
              upward = true,
              path = ctx.dirname,
            })[1] == nil
          end
        '';
      };
    };
  };

  extraPackages = with pkgs; [
    treefmt
    nodePackages.prettier
    gofumpt
    gotools
    stylua
    nixfmt
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
