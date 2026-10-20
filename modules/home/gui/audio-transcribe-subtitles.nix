{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.gui.audio-transcribe-subtitles;
in
{
  options.modules.home.gui.audio-transcribe-subtitles = {
    enable = lib.mkEnableOption "live German-to-English desktop subtitles";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.video-transcribe.packages.${pkgs.stdenv.hostPlatform.system}.audio-transcribe-subtitles
    ];
  };
}
