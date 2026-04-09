{ pkgs, ... }:
{
  extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      pname = "presenting.nvim";
      version = "2026-02-23";
      src = pkgs.fetchFromGitHub {
        owner = "sotte";
        repo = "presenting.nvim";
        rev = "e78245995a09233e243bf48169b2f00dc76341f7";
        sha256 = "sha256-Q/SNFkMSREVEeDiikdMXQCVxrt3iThQUh08YMcN9qSk=";
      };
    })
  ];

  extraConfigLua = ''
    require("presenting").setup({
      options = {
        width = 90,
      },
      parse_frontmatter = true,
      configure_slide_buffer = function(buf)
        local state = _G.Presenting and _G.Presenting._state or nil
        local filetype = state and state.filetype or vim.bo[buf].filetype

        vim.bo[buf].buftype = "nofile"
        vim.bo[buf].filetype = filetype
        vim.bo[buf].bufhidden = "wipe"
        vim.bo[buf].modifiable = false

        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.breakindent = true
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = "no"
        vim.opt_local.conceallevel = 2
        vim.opt_local.concealcursor = "nc"
      end,
    })
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader>P";
      action.__raw = ''
        function()
          local presenting = _G.Presenting
          local inPresentation = presenting and presenting._state ~= nil
          local hasRenderMarkdown, renderMarkdown = pcall(require, "render-markdown")

          if inPresentation then
            vim.cmd("Presenting")
            if hasRenderMarkdown then
              local shouldRestore = vim.g.dejanr_render_markdown_before_presenting
              if shouldRestore ~= nil then
                if shouldRestore then
                  renderMarkdown.enable()
                else
                  renderMarkdown.disable()
                end
                vim.g.dejanr_render_markdown_before_presenting = nil
              end
            end
            return
          end

          if hasRenderMarkdown then
            vim.g.dejanr_render_markdown_before_presenting = renderMarkdown.get()
            if vim.g.dejanr_render_markdown_before_presenting then
              renderMarkdown.disable()
            end
          end

          vim.cmd("Presenting")

          local started = _G.Presenting and _G.Presenting._state ~= nil
          if started then
            return
          end

          if hasRenderMarkdown then
            local shouldRestore = vim.g.dejanr_render_markdown_before_presenting
            if shouldRestore ~= nil then
              if shouldRestore then
                renderMarkdown.enable()
              else
                renderMarkdown.disable()
              end
              vim.g.dejanr_render_markdown_before_presenting = nil
            end
          end
        end
      '';
      options = {
        desc = "Toggle Presenting mode";
        silent = true;
      };
    }
  ];
}
