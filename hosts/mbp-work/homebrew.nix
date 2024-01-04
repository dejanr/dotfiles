{ config, pkgs, lib, ... }: {

    # Homebrew - Mac-specific packages that aren't in Nix
    config = lib.mkIf pkgs.stdenv.isDarwin {
        # Requires Homebrew to be installed
        system.activationScripts.preUserActivation.text = ''
            if ! xcode-select --version 2>/dev/null; then
            $DRY_RUN_CMD xcode-select --install
            fi
            if ! /opt/homebrew/bin/brew --version 2>/dev/null; then
            $DRY_RUN_CMD /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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

            extraConfig = ''
                cask "firefox", args: { language: "en-GB" }
            '';

            taps = [ "homebrew/core" "homebrew/services" "homebrew/cask" "FelixKratz/formulae"];

            brews = [
                "qemu"
                "sketchybar"
                "mas"
                "asciinema"
                "fwup"
                "coreutils"
            ];

            casks = [
                "alacritty"
                "kitty"
                "1password"
                "firefox"
                "google-chrome"
                "slack"
                "spotify"
                "vlc"
                "zoom"
                "mimestream" # Gmail client
            ];

            masApps = {
                "1Password for Safari" = 1569813296;
                "Numbers" = 409203825;
                Alfred = 405843582;
                Keynote = 409183694;
                Pages = 409201541;
                Tailscale = 1475387142;
            };
        };
    };
}
