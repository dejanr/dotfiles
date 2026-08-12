{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  username = "d509506";
in
{
  imports = [
    ./system.nix
  ];

  #fonts.fontDir.enable = true;
  #fonts.fonts = with pkgs; [ (nerdfonts.override { fonts = [ "Iosevka" ]; }) ];

  nix.nrBuildUsers = 32;
  nix.enable = false;

  time.timeZone = "Europe/Berlin";

  services.openssh = {
    enable = true;
    extraConfig = ''
      PubkeyAuthentication yes
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      ChallengeResponseAuthentication no
      PermitRootLogin no
    '';
  };

  services.skhd = {
    enable = true;
    package = pkgs.skhd;
    skhdConfig = "cmd - return : ${pkgs.kitty}/bin/kitty --start-as maximized --single-instance -d ~ &> /dev/null\n\r";
  };

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keyFiles = [
      inputs.ssh-keys.outPath
    ];
  };

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
    pkgs.claude-code
  ];
  environment.shells = [
    pkgs.zsh
  ];

  environment.variables = {
    PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
    ZK_NOTEBOOK_DIR = "$HOME/stuff/notes/";
    EDITOR = "nvim";
    DIRENV_LOG_FORMAT = "";
  };
  environment.darwinConfig = "$HOME/.dotfiles/mbp-work/configuration.nix";
  environment.variables.LANG = "en_US.UTF-8";

  # Darwin GUI modules (example usage)
  # modules.darwin.gui.sketchybar.enable = true;

  # Set primary user for Darwin-specific options
  system.primaryUser = username;
  system.stateVersion = 6;
}
