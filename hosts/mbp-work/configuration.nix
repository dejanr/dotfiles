{ config, lib, inputs, pkgs, ... }:

let
  username = "dejan.ranisavljevic";
  githubKeys = builtins.fetchurl {
    name = "github-ssh-keys";
    url = "https://api.github.com/users/${username}/keys";
    sha256 = "100g2bckwqiaamwynd1k8hjw5vgi83lc5bf10blpnci6p1cr6i8z";
  };
in
{
  imports = [ ./homebrew.nix ./system.nix ];

  #fonts.fontDir.enable = true;
  #fonts.fonts = with pkgs; [ (nerdfonts.override { fonts = [ "Iosevka" ]; }) ];

  nix.nrBuildUsers = 32;

  time.timeZone = "Europe/Berlin";

  services.skhd = {
    enable = true;
    package = pkgs.skhd;
    skhdConfig = "cmd - return : /Applications/kitty.app/Contents/MacOS/kitty --start-as maximized --single-instance -d ~ &> /dev/null\n\r";
  };

  # Nix settings, auto cleanup and enable flakes
  nix = {
    settings = {
      allowed-users = [ username ];
      substituters = [ "https://cache.nixos.org" ];
      trusted-users = [ username "root" ];
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
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowUnsupportedSystem = true;
      android_sdk.accept_license = true;
      permittedInsecurePackages = [ ];
    };
  };

  users = {
    users = {
      "dejan.ranisavljevic" = {
        home = "/Users/dejan.ranisavljevic";
        shell = pkgs.zsh;
      };
    };
  };

  programs.zsh.enable = true;

  environment.systemPackages = [
    pkgs.t
    pkgs.cht-sh
    pkgs.fzf

    pkgs.awscli
    pkgs.gettext
    pkgs.gnupg
    pkgs.mosh
    pkgs.ripgrep
    pkgs.kitty
    pkgs.skhd
  ];
  environment.shells = [ pkgs.zsh ];

  environment.variables = {
    PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
    ZK_NOTEBOOK_DIR = "$HOME/stuff/notes/";
    EDITOR = "nvim";
    DIRENV_LOG_FORMAT = "";
  };
  environment.darwinConfig = "$HOME/.dotfiles/mbp-work/configuration.nix";
  environment.variables.LANG = "en_US.UTF-8";

  system.stateVersion = 5;
}
