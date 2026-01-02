{ ... }:
{
  plugins.which-key = {
    enable = true;
    settings = {
      preset = "helix";
      expand = 0;
      spec = [
        {
          __unkeyed-1 = "<leader>f";
          group = "+File";
          mode = [ "n" "v" ];
        }
        {
          __unkeyed-1 = "<leader>x";
          group = "+Trouble";
          mode = [ "n" "v" ];
        }
        {
          __unkeyed-1 = "<leader>g";
          group = "+Goto";
          mode = [ "n" "v" ];
        }
      ];
      win = {
        border = "single";
        no_overlap = false;
        title_pos = "center";
      };
      sort = [ "manual" "group" "lower" ];
    };
  };
}
