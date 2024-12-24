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
  nix.configureBuildUsers = true;

  time.timeZone = "Europe/London";

  services.activate-system.enable = true;
  services.nix-daemon.enable = true;

  services.skhd = {
    enable = true;
    package = pkgs.skhd;
    skhdConfig = builtins.readFile ./shkd;
  };

  # Nix settings, auto cleanup and enable flakes
  nix = {
    gc.user = username;
    settings = {
      auto-optimise-store = true;
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

    pkgs.awscli
    pkgs.gettext
    pkgs.gnupg
    pkgs.mosh
    pkgs.ripgrep
    pkgs.kitty
  ];
  environment.shells = [ pkgs.zsh ];
  environment.etc = {
    "sudoers.d/10-nix-commands".text = ''
      %admin ALL=(ALL:ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild, \
                                     /run/current-system/sw/bin/nix*, \
                                     /run/current-system/sw/bin/ln, \
                                     /nix/store/*/activate, \
                                     /bin/launchctl
    '';
  };
  environment.variables = {
    PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
    ZK_NOTEBOOK_DIR = "$HOME/stuff/notes/";
    EDITOR = "nvim";
    DIRENV_LOG_FORMAT = "";
  };
  environment.darwinConfig = "$HOME/.dotfiles/mbp-work/configuration.nix";
  environment.variables.LANG = "en_GB.UTF-8";
  environment.loginShell = "${pkgs.zsh}/bin/zsh -l";

  system.stateVersion = 5;
}
