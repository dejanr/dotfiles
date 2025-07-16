{
  config,
  pkgs,
  lib,
  ...
}:
{

  # Homebrew - Mac-specific packages that aren't in Nix
  config = lib.mkIf pkgs.stdenv.isDarwin {
    # Requires Homebrew to be installed
    system.activationScripts.postActivation.text = ''
      if ! xcode-select --version 2>/dev/null; then
      sudo xcode-select --install
      fi
      if ! /opt/homebrew/bin/brew --version 2>/dev/null; then
      sudo -u ${config.system.primaryUser} /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
    '';

    homebrew = {
      enable = true;
      onActivation = {
        upgrade = true;
        autoUpdate = true;
        cleanup = "zap";
      };

      global = {
        autoUpdate = true;
        brewfile = true;
        lockfiles = true;
      };

      taps = [
        "homebrew/services"
        "FelixKratz/formulae"
        "nikitabobko/tap" # aerospace
      ];

      brews = [
        "qemu"
        "sketchybar"
        "mas"
        "asciinema"
        "fwup"
        "coreutils"
        "ollama"
      ];

      casks = [
        "google-chrome"
        "slack"
        "kitty"
        "rectangle"
        "spotify"
        "vlc"
        "zoom"
        "mimestream" # Gmail client
        "nikitabobko/tap/aerospace" # tiling window manager
      ];

      masApps = {
        "Numbers" = 409203825;
        Alfred = 405843582;
        Keynote = 409183694;
        Pages = 409201541;
        Tailscale = 1475387142;
      };
    };
  };
}
