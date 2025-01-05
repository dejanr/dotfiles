{ config, lib, inputs, pkgs, ... }:

{
  imports = [ ../../modules/default.nix ];

  config.programs.firefox = {
    enable = true;

    package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
      extraPolicies = {
        CaptivePortal = false;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DisableFirefoxAccounts = false;
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false;
        OfferToSaveLoginsDefault = false;
        PasswordManagerEnabled = false;
        FirefoxHome = {
          Search = true;
          Pocket = false;
          Snippets = false;
          TopSites = false;
          Highlights = false;
        };
        UserMessaging = {
          ExtensionRecommendations = false;
          SkipOnboarding = true;
        };
      };
    };

    profiles."Personal" = {
      id = 0;
      isDefault = true;
      name = "Personal";
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        # see: https://github.com/nix-community/nur-combined/blob/master/repos/rycee/pkgs/firefox-addons/generated-firefox-addons.nix
        onepassword-password-manager
        privacy-badger
        ublock-origin
        vimium
      ];
    };

    profiles."Work" = {
      id = 1;
      isDefault = false;
      name = "Work";
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        # see: https://github.com/nix-community/nur-combined/blob/master/repos/rycee/pkgs/firefox-addons/generated-firefox-addons.nix
        onepassword-password-manager
        privacy-badger
        ublock-origin
        vimium
      ];
    };
  };

  config.programs.chromium = {
    enable = true;
    extensions = [
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password – Password Manager
      "gighmmpiobklfepjocnamgkkbiglidom" # AdBlock
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # UBlock Origin
      "aapbdbdomjkkjkaonfhkkikfgjllcleb" # Google Translate
      "fmkadmapgofadopljbjfkapdkoienihi" # React Developer Tools
      "okpjlejfhacmgjkmknjhadmkdbcldfcb" # User CSS Override
      "nmgcefdhjpjefhgcpocffdlibknajbmj" # MyMind
    ];
  };

  config.xdg.mimeApps = {
    defaultApplications."x-scheme-handler/http" =
      [ "firefox.desktop" "chromium.desktop" ];
    defaultApplications."x-scheme-handler/https" =
      [ "firefox.desktop" "chromium.desktop" ];
    defaultApplications."text/html" = [ "firefox.desktop" "chromium.desktop" ];
    defaultApplications."x-scheme-handler/about" =
      [ "firefox.desktop" "chromium.desktop" ];
    defaultApplications."x-scheme-handler/unknown" =
      [ "firefox.desktop" "chromium.desktop" ];
  };

  config.modules = {
    # gui
    kitty.enable = true;
    kitty.fontSize = "14.0";

    # cli
    direnv.enable = true;
    git.enable = true;
    nvim.enable = true;
    tmux.enable = true;
    zsh.enable = true;

    # graphical
    hyprland.enable = true;

    # system
    packages.enable = true;
  };
}
