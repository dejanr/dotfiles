{
  pkgs,
  ...
}:

let
  username = "dejanr";
in
{
  nix = {
    enable = false;
    settings = {
      allowed-users = [ "dejanr" ];
      trusted-users = [
        "${username}"
        "root"
      ];

      substituters = [
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };

    gc = {
      interval = {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      };
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

  environment.variables = {
    GOPATH = "$HOME/go";
    XDG_DATA_HOME = "$HOME/.local/share";
    PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
    ZK_NOTEBOOK_DIR = "$HOME/stuff/notes/";
    EDITOR = "nvim";
    DIRENV_LOG_FORMAT = "";
  };

  programs.zsh.enable = true;

  users.users."${username}" = {
    description = "Dejan Ranisavljevic";
    name = username;
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };
}
