{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.home.gui.sway;
in
{
  options.modules.home.gui.sway = {
    enable = mkEnableOption "sway";
  };

  config = mkIf cfg.enable {
    # Enable rofi home manager module.
    programs.rofi.enable = true;
    programs.rofi.package = pkgs.rofi-wayland;
    programs.rofi.font = "PragmataPro 12";

    # Enable and import network-manager-applet
    services.network-manager-applet.enable = true;

    # Enable the blueman applet service.
    services.blueman-applet.enable = true;

    # Enable the playerctld to be able to control music players and mpris-proxy to proxy bluetooth devices.
    services.playerctld.enable = true;
    services.mpris-proxy.enable = true;

    # Set up easyeffects
    services.easyeffects.enable = true;
    services.easyeffects.extraPresets.my-preset = {
      input = {
        blocklist = [ ];
        plugins_order = [ "rnnoise#0" ];
        "rnnoise#0" = {
          bypass = false;
          enable-vad = true;
          input-gain = 0.0;
          model-name = "";
          output-gain = 0.0;
          release = 20.0;
          vad-thres = 95.0;
          wet = 0.0;
        };
      };
    };
    services.easyeffects.preset = "my-preset";

    # Set up a wallpaper manager.
    services.wpaperd.enable = true;
    services.wpaperd.settings = {
      default = {
        duration = "30m";
        mode = "center";
      };
      any.path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/wq/wallhaven-wqery6.jpg";
        sha256 = "0d5416glma4l2sksxszddd6iqchng85j2gf9vc10y14g07cgayg0";
      };
    };

    # Configure swayidle for automatic screen locking
    services.swayidle.enable = true;
    services.swayidle.events = [
      {
        event = "before-sleep";
        command = "${pkgs.swaylock-effects}/bin/swaylock";
      }
      {
        event = "lock";
        command = "${pkgs.swaylock-effects}/bin/swaylock";
      }
    ];
    services.swayidle.timeouts = [
      {
        timeout = 300;
        command = "${pkgs.swaylock-effects}/bin/swaylock";
      }
      {
        timeout = 86400;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];

    home.pointerCursor = {
      enable = true;
      name = "Adwaita";
      size = 24;
      package = pkgs.adwaita-icon-theme;
    };

    home.sessionVariables = {
      SDL_VIDEODRIVER = "wayland";

      # Run QT programs in wayland
      QT_QPA_PLATFORM = "wayland";

      # Set the TERMINAL environment variable for rofi-sensible-terminal
      TERMINAL = "kitty";
    };

    programs.swaylock.enable = true;
    programs.swaylock.package = pkgs.swaylock-effects;
    programs.swaylock.settings = {
      daemonize = true;
      clock = true;
      timestr = "%k:%M";
      datestr = "%Y-%m-%d";
      show-failed-attempts = true;
      indicator = true;
      image = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/wq/wallhaven-wqery6.jpg";
        sha256 = "0d5416glma4l2sksxszddd6iqchng85j2gf9vc10y14g07cgayg0";
      };
    };

    wayland.systemd.target = "sway-session.target";

    wayland.windowManager.sway = {
      enable = true;
      systemd.enable = true;

      wrapperFeatures.base = true;
      wrapperFeatures.gtk = true;

      config =
        let
          rofi = pkgs.rofi.override { plugins = [ pkgs.rofi-emoji ]; };
          pactl = "${pkgs.pavucontrol}/bin/pactl";

          # Set default modifier
          modifier = "Mod4";

          # Direction keys (vim logic)
          left = "h";
          right = "l";
          up = "k";
          down = "j";
        in
        {
          # Set default modifier
          inherit
            modifier
            left
            right
            up
            down
            ;

          keybindings = {
            # Run terminal
            "${modifier}+Return" = "exec ${pkgs.kitty}/bin/kitty";

            # Power Menu
            "${modifier}+Escape" = "exec ${pkgs.wlogout}/bin/wlogout --margin-left 500 --margin-right 500";

            # Scratchpad
            "${modifier}+minus" =
              "exec ${pkgs.sway-scratchpad}/bin/sway-scratchpad --width 50 --height 80 --command \"${pkgs.kitty}/bin/kitty -e ${pkgs.scratchpad}/bin/scratchpad\" --mark terminal";

            # Run Launcher
            "${modifier}+d" =
              "exec ${pkgs.rofi-wayland}/bin/rofi -show combi -modi combi -combi-modes 'window,drun' | xargs swaymsg exec --";

            # Run rofi emoji picker
            "${modifier}+i" = "exec ${rofi}/bin/rofi -show emoji";

            # Printscreen
            Print = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.swappy}/bin/swappy -f -";

            # Backlight:
            XF86MonBrightnessUp = "exec ${pkgs.acpilight}/bin/xbacklight -inc 10";
            XF86MonBrightnessDown = "exec ${pkgs.acpilight}/bin/xbacklight -dec 10";

            # Audio:
            XF86AudioMute = "exec ${pactl} set-sink-mute @DEFAULT_SINK@ toggle";
            XF86AudioLowerVolume = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ -10%";
            XF86AudioRaiseVolume = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ +10%";
            XF86AudioMicMute = "exec ${pactl} set-source-mute @DEFAULT_SOURCE@ toggle";
            XF86AudioPrev = "exec ${pkgs.playerctl}/bin/playerctl previous";
            XF86AudioPlay = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
            XF86AudioNext = "exec ${pkgs.playerctl}/bin/playerctl next";

            # Launch screen locker
            "${modifier}+Shift+l" = "exec ${pkgs.swaylock-effects}/bin/swaylock";

            # Kill focused window
            "${modifier}+q" = "kill";

            # Move focus around:
            "${modifier}+${left}" = "focus left";
            "${modifier}+${right}" = "focus right";
            "${modifier}+${up}" = "focus up";
            "${modifier}+${down}" = "focus down";

            # Move focused window:
            "${modifier}+Alt+${left}" = "move left";
            "${modifier}+Alt+${right}" = "move right";
            "${modifier}+Alt+${up}" = "move up";
            "${modifier}+Alt+${down}" = "move down";

            # Switch to workspace:
            "${modifier}+0" = "workspace number 10";
            "${modifier}+1" = "workspace number 1";
            "${modifier}+2" = "workspace number 2";
            "${modifier}+3" = "workspace number 3";
            "${modifier}+4" = "workspace number 4";
            "${modifier}+5" = "workspace number 5";
            "${modifier}+6" = "workspace number 6";
            "${modifier}+7" = "workspace number 7";
            "${modifier}+8" = "workspace number 8";
            "${modifier}+9" = "workspace number 9";

            # Move focused container to workspace:
            "${modifier}+Shift+0" = "move container to workspace number 0; worspace number 10";
            "${modifier}+Shift+1" = "move container to workspace number 1; workspace number 1";
            "${modifier}+Shift+2" = "move container to workspace number 2; workspace number 2";
            "${modifier}+Shift+3" = "move container to workspace number 3; workspace number 3";
            "${modifier}+Shift+4" = "move container to workspace number 4; workspace number 4";
            "${modifier}+Shift+5" = "move container to workspace number 5; workspace number 5";
            "${modifier}+Shift+6" = "move container to workspace number 6; workspace number 6";
            "${modifier}+Shift+7" = "move container to workspace number 7; workspace number 7";
            "${modifier}+Shift+8" = "move container to workspace number 8; workspace number 8";
            "${modifier}+Shift+9" = "move container to workspace number 9; workspace number 9";

            # Switch Between Workspaces
            "${modifier}+a" = "workspace back_and_forth";

            # Split in horizontal orientation:
            "${modifier}+Shift+h" = "split h";

            # Split in vertical orientation:
            "${modifier}+Shift+v" = "split v";

            # Change layout of focused container:
            "${modifier}+o" = "layout stacking";
            "${modifier}+comma" = "layout tabbed";
            "${modifier}+period" = "layout toggle split";

            # Fullscreen for the focused container:
            "${modifier}+Shift+f" = "fullscreen toggle";

            # Toggle the current focus between tiling and floating mode:
            "${modifier}+Shift+space" = "floating toggle";

            # Swap focus between the tiling area and the floating area:
            "${modifier}+space" = "focus mode_toggle";

            # Enter other modes:
            "${modifier}+Shift+r" = "mode resize";
            "${modifier}+Shift+x" = "reload";

            # Apps
            "${modifier}+w" = " exec --no-startup-id google-chrome-stable --args --profile-directory=Personal";
            "${modifier}+e" = " exec --no-startup-id google-chrome-stable --args --profile-directory=Work";
            "${modifier}+r" =
              " exec --no-startup-id google-chrome-stable --args --profile-directory=Consulting";
            "${modifier}+t" = " exec ${pkgs.kitty}/bin/kitty -e zsh -ic yazi";
            "${modifier}+m" = " exec ${pkgs.kitty}/bin/kitty -e btop";
          };

          modes.resize = {
            "${left}" = "resize shrink width 10px"; # Pressing left will shrink the window’s width.
            "${right}" = "resize grow width 10px"; # Pressing right will grow the window’s width.
            "${up}" = "resize shrink height 10px"; # Pressing up will shrink the window’s height.
            "${down}" = "resize grow height 10px"; # Pressing down will grow the window’s height.

            # You can also use the arrow keys:
            Left = "resize shrink width 10px";
            Down = "resize grow height 10px";
            Up = "resize shrink height 10px";
            Right = "resize grow width 10px";

            # Exit mode
            Return = "mode default";
            Escape = "mode default";
            "${modifier}+r" = "mode default";
          };
          modes.passthrough = {
            "${modifier}+Shift+r" = "mode default";
          };

          focus.wrapping = "workspace";
          focus.newWindow = "urgent";
          fonts = {
            names = [ "PragmataPro Mono" ];
            size = "14";
          };
          gaps.inner = 5;

          defaultWorkspace = "workspace number 1";

          window.commands = [
            # Set borders instead of title bars for some programs
            {
              criteria.app_id = "kitty";
              command = "border pixel 0";
            }
            {
              criteria.class = "Google-chrome";
              command = "border pixel 0";
            }
            {
              criteria.class = "Slack";
              command = "border pixel 0";
            }
            {
              criteria.app_id = "wlroots";
              command = "border pixel 0";
            }

            # Set opacity for some programs
            {
              criteria.app_id = "kitty";
              command = "opacity set 0.95";
            }
          ];

          # Make some programs floating
          floating.criteria = [
            {
              app_id = ".blueman-manager-wrapped";
              title = "Bluetooth Devices";
            }
          ];

          # Set a custom keymap
          input."type:keyboard".xkb_layout = "us";
          input."type:keyboard".xkb_options = "terminate:ctrl_alt_bksp";

          startup = [
            { command = "${pkgs.mako}/bin/mako"; }

            # Import variables needed for screen sharing and gnome3 pinentry to work.
            { command = "${pkgs.dbus}/bin/dbus-update-activation-environment WAYLAND_DISPLAY"; }

            # Import user environment PATH to systemctl as user and then restart the xdg-desktop-portal
            # This is to get xdg-open to work in flatpaks to be able to open links inside of flatpaks.
            {
              command = "${pkgs.systemd}/bin/systemctl --user import-environment PATH && ${pkgs.systemd}/bin/systemctl --user restart xdg-desktop-portal.service";
            }
          ];

          # Disable the default bar
          bars = [ { mode = "invisible"; } ];

          # Assign windows
          assigns = {
            "4" = [ { class = "Steam"; } ];
          };
        };
    }; # END sway
  };
}
