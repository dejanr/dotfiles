{ theme }:

let themes = rec {

  "dark" = themes."nightfox";
  "light" = themes."dayfox";

  "nightfox" = rec {
    dark = true;
    foreground = "#cdcecf";
    background = "#262626";
    cursorColor = "#cdcecf";

    black = color0;
    color0 = "#393b44";
    color8 = "#575860";
    red = color1;
    color1 = "#c94f6d";
    color9 = "#d16983";
    green = color2;
    color2 = "#81b29a";
    color10 = "#8ebaa4";
    yellow = color3;
    color3 = "#dbc074";
    color11 = "#e0c989";
    blue = color4;
    color4 = "#719cd6";
    color12 = "#86abdc";
    magenta = color5;
    color5 = "#9d79d6";
    color13 = "#baa1e2";
    cyan = color6;
    color6 = "#63cdcf";
    color14 = "#7ad5d6";
    white = color7;
    color7 = "#dfdfe0";
    color15 = "#e4e4e5";
  };

  "dayfox" = rec {
    dark = false;
    foreground = "#3d2b5a";
    background = "#f6f2ee";
    cursorColor = "#3d2b5a";

    black = color0;
    color0 = "#352c24";
    color8 = "#534c45";
    red = color1;
    color1 = "#a5222f";
    color9 = "#b3434e";
    green = color2;
    color2 = "#396847";
    color10 = "#577f63";
    yellow = color3;
    color3 = "#ac5402";
    color11 = "#b86e28";
    blue = color4;
    color4 = "#2848a9";
    color12 = "#4863b6";
    magenta = color5;
    color5 = "#6e33ce";
    color13 = "#8452d5";
    cyan = color6;
    color6 = "#287980";
    color14 = "#488d93";
    white = color7;
    color7 = "#f2e9e1";
    color15 = "#f4ece6";
  };
}; in themes.${theme} or themes."terafox"
