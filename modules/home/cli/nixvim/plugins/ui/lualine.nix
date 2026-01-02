{ ... }:
{
  plugins.lualine = {
    enable = true;
    settings = {
      options = {
        theme = "catppuccin";
        component_separators = {
          left = "";
          right = "";
        };
        section_separators = {
          left = "";
          right = "";
        };
        globalstatus = true;
      };
    };
  };

  plugins.web-devicons.enable = true;
}
