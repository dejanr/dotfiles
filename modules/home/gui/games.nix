{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.home.gui.games;

in
{
  options.modules.home.gui.games = {
    enable = mkEnableOption "gaming applications";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Games and game launchers
      jeveassets
      legendary-gl # A free and open-source Epic Games Launcher alternative
      heroic # Native GOG, Epic, and Amazon Games Launcher for Linux, Windows and Mac
      protonup-qt

      # Gaming utilities and overlays
      mangohud # A Vulkan and OpenGL overlay for monitoring FPS, temperatures, CPU/GPU load and more
      libstrangle # Frame rate limiter for Linux/OpenGL

      # Communication apps for gaming
      discord-canary
      teamspeak_client # voip client
      mumble # Low-latency, high quality voice chat software

      # EVE Online tools
      pyfa
    ];
  };
}
