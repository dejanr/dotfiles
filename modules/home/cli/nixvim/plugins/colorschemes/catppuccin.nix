{ ... }:
{
  colorschemes.catppuccin = {
    enable = true;
    settings = {
      flavour = "mocha";
      transparent_background = false;
      show_end_of_buffer = false;
      term_colors = true;
      dim_inactive = {
        enabled = false;
        shade = "dark";
        percentage = 0.15;
      };
      styles = {
        comments = [ "italic" ];
        conditionals = [ "italic" ];
        loops = [ ];
        functions = [ ];
        keywords = [ ];
        strings = [ ];
        variables = [ ];
        numbers = [ ];
        booleans = [ ];
        properties = [ ];
        types = [ ];
        operators = [ ];
      };
      integrations = {
        cmp = true;
        gitsigns = true;
        nvimtree = true;
        treesitter = true;
        telescope.enabled = true;
        lsp_trouble = true;
        which_key = true;
      };
    };
  };
}
