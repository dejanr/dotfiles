{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.hyprland;
in {
  options.modules.hyprland = { enable = mkEnableOption "hyprland"; };

  config = mkIf cfg.enable {
  gtk.iconTheme = {
    name = "Gruvbox Plus Dark";
    package = pkgs.callPackage ./icons/gruvbox-plus-dark.nix { };
  };

  xdg.desktopEntries = {
    Helix = {
      name = "Helix";
      noDisplay = true;
    };
    nvim = {
      name = "NeoVim";
      noDisplay = true;
    };
    cups = {
      name = "Printing";
      noDisplay = true;
    };
  };

    home.packages = [ pkgs.wofi pkgs.dolphin pkgs.kitty ];

    home.sessionVariables = {
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
    };

    wayland.windowManager.hyprland = {
      enable = true;

      systemd.variables = [ "--all" ];

      settings = {
        "$mod" = "SUPER";

        "$terminal" = "kitty";
        "$fileManager" = "dolphin";
        "$menu" = "wofi --show drun";

        exec-once = [
          "blueman-applet"
          "nm-applet"
          "telegram-desktop -startintray"
          "hyprpaper"
        ];

        env = [
          "QT_QPA_PLATFORMTHEME, gtk3" # for telegram file manager

          "XDG_CURRENT_DESKTOP, Hyprland" # for display manager and other
          "XDG_SESSION_TYPE, wayland"
          "XDG_SESSION_DESKTOP, Hyprland"
        ];

        input = {
          kb_layout = "us";
          follow_mouse = 1;
          touchpad = {
            natural_scroll = true;
            disable_while_typing = true;
            tap-to-click = false;
            middle_button_emulation = false;
          };
          sensitivity = 0;
        };

        misc = {
          disable_hyprland_qtutils_check = true;

          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;

          layers_hog_keyboard_focus = true;
          animate_manual_resizes = true;

          enable_swallow = true;
          swallow_regex = "^(kitty)$";
        };

        general = {
          gaps_in = 2;
          gaps_out = 0;
          border_size = 0;
        };

        decoration = {
          rounding = 0;
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.1696;
          };
          shadow.enabled = false;
        };

        animations = {
          enabled = true;
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.00";
          animation = [
            "workspaces, 1, 3, myBezier, fade"
            "windows, 1, 3, myBezier, popin"
            "windowsOut, 1, 3, myBezier"
            "border, 0"
            "borderangle, 1, 3, myBezier"
            "fade, 1, 3, myBezier"
          ];
        };

        bind =
          [
            "$mod, Return, exec, $terminal"
            "$mod, d, exec, $menu"
            "$mod, q, killactive, "
          ]
          ++ (
            # workspaces
            # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
            builtins.concatLists (builtins.genList
              (i:
                let ws = i + 1;
                in [
                  "$mod, code:1${toString i}, workspace, ${toString ws}"
                  "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
                ]
              )
              9)
          );
      };
    };
  };
}
