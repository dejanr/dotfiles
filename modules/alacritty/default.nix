{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.modules.alacritty;
in
{
  options.modules.alacritty = { enable = mkEnableOption "alacritty"; };

  config = mkIf cfg.enable {
    programs.alacritty = {
        enable = true;
        settings = {
            window = {
                opacity = 0.90;
                padding = {x = 0; y = 0;};
                startup_mode = "Maximized";
                decorations = "None";
            };

            env.TERM = "xterm-256color";

            scrolling = {
                history = 10000;
                multiplier = 3;
            };

            mouse = { hide_when_typing = true; };

            key_bindings = [
                {
                # clear terminal
                key = "K";
                mods = "Control";
                chars = "\\x0c";
                }
            ];

            font = let fontname = "PragmataPro Mono"; in
                {
                    normal = { family = fontname; style = "Regular"; };
                    bold = { family = fontname; style = "Bold"; };
                    italic = { family = fontname; style = "Italic"; };
                    size = 18;
                };

            cursor.style = "Block";


            # nightfox
            colors = {
                primary = {
                    background = "0x1c1c1c";
                    foreground = "0xcdcecf";
                };
                normal = {
                    black=   "0x393b44";
                    red=     "0xc94f6d";
                    green=   "0x81b29a";
                    yellow=  "0xdbc074";
                    blue=    "0x719cd6";
                    magenta= "0x9d79d6";
                    cyan=    "0x63cdcf";
                    white=   "0xdfdfe0";
                };
                bright = {
                    black =   "0x575860";
                    red =     "0xd16983";
                    green =   "0x8ebaa4";
                    yellow =  "0xe0c989";
                    blue =    "0x86abdc";
                    magenta = "0xbaa1e2";
                    cyan =    "0x7ad5d6";
                    white =   "0xe4e4e5";
                };
                indexed_colors = [
                    { index = 16; color = "0xf4a261"; }
                    { index = 17; color = "0xd67ad2"; }
                ];
            };

            selection = {
                # This string contains all characters that are used as separators for
                # "semantic words" in Alacritty.
                semantic_escape_chars = ",│`| = \"' ()[]{}<>\t";

                # When true, selected text will be copied to the primary clipboard
                save_to_clipboard = true;
            };
        };
    };
  };
}
