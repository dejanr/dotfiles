{ ... }:
{
  plugins.zen-mode = {
    enable = true;
    settings = {
      window = {
        width = 120;
        options = {
          number = false;
          relativenumber = false;
        };
      };
    };
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>z";
      action = "<cmd>ZenMode<cr>";
      options = {
        desc = "Toggle Zen Mode";
        silent = true;
      };
    }
  ];
}
