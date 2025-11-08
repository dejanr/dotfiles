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
      mangohud # A Vulkan and OpenGL overlay for monitoring FPS, temperatures, CPU/GPU load and more
      libstrangle # Frame rate limiter for Linux/OpenGL

      # Communication apps for gaming
      discord
      vesktop # discord alternative
      dorion # discord alternative
      mumble # Low-latency, high quality voice chat software

      # EVE Online tools
      pyfa

      protonplus
    ];
  };
}
