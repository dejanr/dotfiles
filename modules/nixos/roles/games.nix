{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;
let
  cfg = config.modules.nixos.roles.games;
  isX86 = pkgs.stdenv.hostPlatform.isx86_64;

in
{
  options.modules.nixos.roles.games = {
    enable = mkEnableOption "gaming system integration";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = with pkgs; [
        gamemode
        vulkan-loader
        vulkan-validation-layers
        vulkan-tools
        jstest-gtk
        linuxConsoleTools
      ];

      programs.gamemode = {
        enable = true;
        enableRenice = true;
        settings = {
          general.renice = -20;
        };
      };
    }

    (mkIf isX86 (
      let
        nixGamingPkgs = inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system};
      in
      {
        environment.systemPackages =
          with pkgs;
          [
            appimage-run
            cabextract
            libstrangle
          ]
          ++ (with nixGamingPkgs; [
            dxvk
            vkd3d-proton
            wine-tkg
            wineprefix-preparer
            winetricks-git
          ]);

        programs = {
          steam = {
            enable = true;
            protontricks.enable = true;
            gamescopeSession.enable = true;
            extraPackages = with pkgs; [ libstrangle ];
            remotePlay.openFirewall = true;
            dedicatedServer.openFirewall = true;
            package = pkgs.steam.override {
              extraPkgs = (
                pkgs: with pkgs; [
                  gamemode
                ]
              );
            };
          };
          gamescope = {
            enable = true;
            capSysNice = true;
          };
        };

        hardware.steam-hardware.enable = true;
      }
    ))
  ]);
}
