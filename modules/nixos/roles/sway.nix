{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.nixos.theme;
in
{
  options.modules.nixos.roles.sway = {
    enable = mkEnableOption "sway window manager system integration";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.bluetuith
      pkgs.evince
      pkgs.adwaita-icon-theme # Icons for gnome packages that sometimes use them but don't depend on them
      pkgs.pavucontrol
      pkgs.wdisplays
      pkgs.wlr-randr
    ];

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true; # so that gtk works properly
      extraPackages = with pkgs; [
        swaylock-effects
        swayidle
        wl-clipboard
        wf-recorder
        mako # notification daemon
        grim
        #kanshi
        slurp
        kitty # Alacritty is the default terminal in the config
        dmenu # Dmenu is the default in the config but i recommend wofi since its wayland native
      ];
      extraSessionCommands = ''
        export SDL_VIDEODRIVER=wayland
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        export _JAVA_AWT_WM_NONREPARENTING=1
        export MOZ_ENABLE_WAYLAND=1
      '';
    };

    services.greetd.enable = true;
    services.greetd.settings.default_session =
      let
        sway = pkgs.writeTextFile {
          name = "sway-wrapper";
          executable = true;
          text = ''
            #!${pkgs.zsh}/bin/zsh
            SHLVL=0
            for profile in ''${(z)NIX_PROFILES}; do
              fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
            done
            exec sway --unsupported-gpu 2>&1
          '';
          checkPhase = ''
            ${pkgs.stdenv.shellDryRun} "$target"
          '';
        };
      in

      {
        command = "${pkgs.tuigreet}/bin/tuigreet --remember --time --cmd ${sway}";
        user = "greeter";
      };

    # Set up XDG Portals
    xdg.portal.enable = true;
    xdg.portal.extraPortals = with pkgs; [ xdg-desktop-portal-wlr ];

    services.displayManager.sessionPackages = [
      (
        pkgs.writeTextFile {
          name = "sway-session";
          destination = "/share/wayland-sessions/sway.desktop";
          text = ''
            [Desktop Entry]
            Name=Sway
            Comment=An i3-compatible Wayland compositor
            Exec=${
              pkgs.writeTextFile {
                name = "sway-wrapper";
                executable = true;
                text = ''
                  #!${pkgs.zsh}/bin/zsh
                  SHLVL=0
                  for profile in ''${(z)NIX_PROFILES}; do
                    fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
                  done
                  exec sway --unsupported-gpu 2>&1 >> $XDG_CACHE_HOME/sway
                '';
                checkPhase = ''
                  ${pkgs.stdenv.shellDryRun} "$target"
                '';
              }
            }
            Type=Application
          '';
        }
        // {
          providedSessions = [ pkgs.sway.meta.mainProgram ];
        }
      )
    ];
  };
}
