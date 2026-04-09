{ pkgs, ... }:
{
  extraPlugins = with pkgs.vimPlugins; [
    render-markdown-nvim
  ];

  extraConfigLua = ''
    require("render-markdown").setup({
      enabled = true,
      file_types = { "markdown", "mdx" },
      render_modes = { "n", "c", "t" },
      anti_conceal = {
        enabled = true,
        above = 1,
        below = 1,
      },
      completions = {
        lsp = {
          enabled = true,
        },
      },
    })
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader>mr";
      action = "<cmd>RenderMarkdown toggle<cr>";
      options = {
        desc = "Toggle markdown render";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>mR";
      action = "<cmd>RenderMarkdown preview<cr>";
      options = {
        desc = "Preview rendered markdown";
        silent = true;
      };
    }
  ];
}
