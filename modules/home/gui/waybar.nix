{
  pkgs,
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.home.gui.waybar;

in
{
  options.modules.home.gui.waybar = {
    enable = mkEnableOption "Enable waybar bar for wayland";
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      style = pkgs.runCommand "waybar-styles.css" { } ''
        sed -e 's/font-family: /font-family: PragmataPro, /'              \
            -e 's/font-size: 13px/font-size: 13px/' \
            ${./waybar/style.css} > $out
      '';
      settings = [
        {
          # Height of bar
          height = 30;

          # Margins for bar
          margin-top = 0;
          margin-bottom = 0;
          margin-right = 0;
          margin-left = 0;

          modules-left = [
            "sway/workspaces"
            "sway/mode"
            "sway/scratchpad"
          ];
          modules-center = [ ];
          modules-right = [
            "mpris"
            "idle_inhibitor"
            "cpu"
            "memory"
            "pulseaudio"
            "clock"
            "tray"
          ];

          "sway/workspaces" = {
            disable-scroll = true;
            format = "{icon}";
            format-icons = {
              "1" = "1: ";
              "2" = "2: ";
              "3" = "3: ";
              "4" = "4: ";
              "5" = "5: ";
              "6" = "6: ";
              "7" = "7: ";
              "8" = "8: ";
              "9" = "9: ";
              "10" = "10: ";
              default = "";
            };
          };

          "sway/scratchpad" = {
            format = "{icon}";
            format-icons = [
              ""
            ];
            show-empty = false;
          };

          "sway/mode".format = "<span style=\"italic\">{}</span>";

          mpris = {
            format = "{player_icon} {status_icon} {dynamic}";
            format-paused = "{player_icon} {status_icon} <i>{dynamic}</i>";
            tooltip-format = "{player_icon} {status_icon} {dynamic}";
            tooltip-format-paused = "{player_icon} {status_icon} {dynamic}";
            artist-len = 15;
            album-len = 0;
            title-len = 30;
            dynamic-len = 40;
            player-icons = {
              default = "";
              firefox = "";
              spotify = "";
            };
            status-icons = {
              default = "▶";
              paused = "⏸";
            };
          };

          backlight.format = "{percent}% {icon}";
          backlight.format-icons = [
            ""
            ""
          ];

          battery.format = "{capacity}% {icon}";
          battery.format-alt = "{time} {icon}";
          battery.format-charging = "{capacity}% ";
          battery.format-full = "{capacity}% {icon}";
          battery.format-good = "{capacity}% {icon}";
          battery.format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
          battery.format-plugged = "{capacity}% ";
          battery.states = {
            good = 80;
            warning = 30;
            critical = 15;
          };

          clock.format = "<span color=\"#88c0d0\"></span> {:%H:%M}";
          clock.interval = 5;
          clock.tooltip = false;

          cpu.format = "{usage}% ";
          cpu.tooltip = true;

          idle_inhibitor.format = "{icon}";
          idle_inhibitor.format-icons.activated = "";
          idle_inhibitor.format-icons.deactivated = "";

          memory.format = "{}% ";

          network.format-alt = "{ifname}: {ipaddr}/{cidr}";
          network.format-disconnected = "Disconnected ⚠";
          network.format-ethernet = "{ifname}: {ipaddr}/{cidr} ";
          network.format-linked = "{ifname} (No IP) ";
          network.format-wifi = "{essid} ({signalStrength}%) ";
          network.interval = 15;

          pulseaudio.format = "{volume}% {icon} {format_source}";
          pulseaudio.format-bluetooth = "{volume}% {icon} {format_source}";
          pulseaudio.format-bluetooth-muted = " {icon} {format_source}";
          pulseaudio.format-muted = " {format_source}";
          pulseaudio.format-source = "{volume}% ";
          pulseaudio.format-source-muted = "";
          pulseaudio.format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
          pulseaudio.on-click = "${pkgs.pavucontrol}/bin/pavucontrol";

          temperature.critical-threshold = 80;
          temperature.format = "{icon} {temperatureC}°C";
          temperature.format-icons = [
            ""
            ""
          ];

          tray.spacing = 12;
        }
      ];
    }; # END waybar
  };
}
