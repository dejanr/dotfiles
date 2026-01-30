{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.home.gui.games;
  isX86 = pkgs.stdenv.hostPlatform.isx86_64;
  isAarch64 = pkgs.stdenv.hostPlatform.isAarch64;

in
{
  options.modules.home.gui.games = {
    enable = mkEnableOption "gaming applications";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        vesktop # discord alternative
        mumble # Low-latency, high quality voice chat software
      ]
      ++ optionals isX86 [
        mangohud # A Vulkan and OpenGL overlay for monitoring FPS, temperatures, CPU/GPU load and more
        libstrangle # Frame rate limiter for Linux/OpenGL
        discord
        pyfa
        protonplus
      ]
      ++ optionals isAarch64 [
        fex
        muvm
      ];
  };
}
