{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.home.theme;
in
{
  options.modules.home.theme = {
    enable = mkEnableOption "Enable theme settings";
    flavor = lib.mkOption {
      type = lib.types.str;
      default = "mocha";
    };
  };

  config = mkIf cfg.enable {
    catppuccin.flavor = config.modules.home.theme.flavor;

    # Enable catppuchin for on home manager level for different applications.
    catppuccin.alacritty.enable = true;
    catppuccin.foot.enable = true;
    catppuccin.fish.enable = true;
    catppuccin.rofi.enable = true;
    catppuccin.mako.enable = true;
    catppuccin.swaylock.enable = true;

    # Bat module and theme
    programs.bat.enable = true;
    catppuccin.bat.enable = true;

    # Fzf module and theme
    programs.fzf.enable = true;
    catppuccin.fzf.enable = true;

    # Imv module and theme
    programs.imv.enable = true;
    catppuccin.imv.enable = true;

    # Set up theme for sway.
    catppuccin.sway.enable = true;
    wayland.windowManager.sway.config.colors =
      let
        background = "$base";
        focusedInactive = {
          background = "$base";
          border = "$overlay0";
          childBorder = "$overlay0";
          indicator = "$rosewater";
          text = "$text";
        };
        focused = {
          background = "$base";
          border = "$lavender";
          childBorder = "$lavender";
          indicator = "$rosewater";
          text = "$text";
        };
        urgent = {
          background = "$base";
          border = "$peach";
          childBorder = "$peach";
          indicator = "$overlay0";
          text = "$peach";
        };
        unfocused = focusedInactive;
        "placeholder" = focusedInactive;
      in
      {
        inherit
          background
          focused
          focusedInactive
          urgent
          unfocused
          "placeholder"
          ;
      };

    # Set up theme for waybar.
    catppuccin.waybar.enable = true;
    catppuccin.waybar.mode = "createLink";
  };
}
