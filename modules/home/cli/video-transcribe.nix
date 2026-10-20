{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.cli.video-transcribe;
in
{
  options.modules.home.cli.video-transcribe = {
    enable = lib.mkEnableOption "local video and audio transcription with automatic GPU selection";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.video-transcribe.packages.${pkgs.stdenv.hostPlatform.system}.video-transcribe
    ];
  };
}
