{ ... }:
{
  keymaps = [
    # File operations
    {
      mode = "n";
      key = "<leader>fs";
      action = ":w!<cr>";
      options = {
        desc = "Save File";
        silent = true;
      };
    }

    # Show diagnostics in float
    {
      mode = "n";
      key = "<leader>e";
      action = "<cmd>lua vim.diagnostic.open_float()<CR>";
      options = {
        desc = "Show diagnostics";
        silent = true;
      };
    }

    # Buffer navigation
    {
      mode = "n";
      key = "[b";
      action = ":bprevious<cr>";
      options.silent = true;
    }
    {
      mode = "n";
      key = "]b";
      action = ":bnext<cr>";
      options.silent = true;
    }

    # Window navigation
    {
      mode = "n";
      key = "<C-h>";
      action = "<C-w>h";
      options.silent = true;
    }
    {
      mode = "n";
      key = "<C-j>";
      action = "<C-w>j";
      options.silent = true;
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<C-w>k";
      options.silent = true;
    }
    {
      mode = "n";
      key = "<C-l>";
      action = "<C-w>l";
      options.silent = true;
    }

    # Quit
    {
      mode = "n";
      key = "<leader>q";
      action = ":q!<cr>";
      options.silent = true;
    }

    # Movement improvements (j/k work on visual lines)
    {
      mode = "n";
      key = "j";
      action = "gj";
      options.silent = true;
    }
    {
      mode = "n";
      key = "k";
      action = "gk";
      options.silent = true;
    }
    {
      mode = "n";
      key = ";";
      action = ":";
      options.silent = false;
    }

    # Location list navigation
    {
      mode = "";
      key = "<C-n>";
      action = ":lnext<cr>";
      options.silent = true;
    }
    {
      mode = "";
      key = "<C-p>";
      action = ":lprevious<cr>";
      options.silent = true;
    }

    # Toggle highlight search
    {
      mode = "n";
      key = "<leader>n";
      action = ":set invhls<cr>:set hls?<cr>";
      options = {
        desc = "Turn off highlight";
        silent = true;
      };
    }

    # Toggle commands (require utils module)
    {
      mode = "n";
      key = "<leader>tl";
      action = ":ToggleLocList<cr>";
      options = {
        desc = "Toggle location list";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>tq";
      action = ":ToggleQF<cr>";
      options = {
        desc = "Toggle quickfix list";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>tp";
      action = ":set invpaste<CR>:set paste?<cr>";
      options = {
        desc = "Toggle paste mode";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>ts";
      action = ":nohlsearch<cr>";
      options = {
        desc = "Toggle search highlighting";
        silent = true;
      };
    }
  ];

  # Extra Lua for utils toggle functions
  extraConfigLua = ''
    -- Define toggle commands using utils module
    vim.cmd([[command! -nargs=0 -bar ToggleLocList lua require('dejanr.utils').ToggleLocList()]])
    vim.cmd([[command! -nargs=0 -bar ToggleQF lua require('dejanr.utils').ToggleQF()]])
  '';
}
