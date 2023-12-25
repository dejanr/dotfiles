{ config, lib, inputs, pkgs, ... }:

let
  username = "dejan.ranisavljevic";
  githubKeys = builtins.fetchurl {
    name = "github-ssh-keys";
    url = "https://api.github.com/users/${username}/keys";
    sha256 = "15a0vmngmp3453nk7a6jd8kyph4qhcfzljdsrank3h9fgbf12xng";
  };
in
{
  imports = [];

  programs.zsh.enable = true;
              
  system.defaults.NSGlobalDomain.AppleKeyboardUIMode = 3;
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 10;
  system.defaults.NSGlobalDomain.KeyRepeat = 1;
  system.defaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
  system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
  system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;

  system.defaults.dock.autohide = true;
  system.defaults.dock.mru-spaces = false;
  system.defaults.dock.orientation = "left";
  system.defaults.dock.showhidden = true;

  system.defaults.finder.AppleShowAllExtensions = true;
  system.defaults.finder.QuitMenuItem = true;
  system.defaults.finder.FXEnableExtensionChangeWarning = false;

  system.defaults.trackpad.Clicking = true;

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;


  environment.systemPackages = [
    pkgs.t
    
    pkgs.awscli
    pkgs.curl
    pkgs.direnv
    pkgs.gettext
    pkgs.git
    pkgs.gnupg
    pkgs.htop
    pkgs.jq
    pkgs.mosh
    pkgs.ripgrep
  ];

  # Set environment variables
  environment.variables = {
    PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
    ZK_NOTEBOOK_DIR = "$HOME/stuff/notes/";
    EDITOR = "nvim";
    DIRENV_LOG_FORMAT = "";
  };

  nix.nrBuildUsers = 32;
  nix.configureBuildUsers = true;

  # Nix settings, auto cleanup and enable flakes
  nix = {
    settings = {
      auto-optimise-store = true;
      allowed-users = [ "dejanr" ];
      substituters = [ "https://cache.nixos.org" ];
      trusted-users = [ "${username}" "root" ];
    };

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };

    extraOptions = ''
          experimental-features = nix-command flakes
          keep-outputs = true
          keep-derivations = true
    '';

    package = pkgs.nixVersions.stable;
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowUnsupportedSystem = true;
      android_sdk.accept_license = true;
      permittedInsecurePackages = [
      ];
    };
  };

  environment.darwinConfig = "$HOME/.dotfiles/mbp-work/configuration.nix";

  services.nix-daemon.enable = true;
}
