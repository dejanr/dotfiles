# modules/shell/zsh.nix --- ...

{ config, options, pkgs, lib, ... }:
with lib; {
  options.modules.shell.zsh = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.zsh.enable {
    my = {
      packages = with pkgs; [
        zsh
        nix-zsh-completions
        bat
        exa
        fasd
        fd
        fzf
        htop
        tldr
        tree
      ];
      env.ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
      env.ZSH_CACHE = "$XDG_CACHE_HOME/zsh";

      alias.exa = "exa --group-directories-first";
      alias.l = "exa -1";
      alias.ll = "exa -lg";
      alias.la = "LC_COLLATE=C exa -la";
      alias.sc = "systemctl";
      alias.ssc = "sudo systemctl";

      # Write it recursively so other modules can write files to it
      home.xdg.configFile."zsh" = {
        source = <config/zsh>;
        recursive = true;
      };

      home.programs.zsh = {
        enable = true;
        enableCompletion = true;
        plugins = [{
          name = "zsh-nix-shell";
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.1.0";
            sha256 = "0snhch9hfy83d4amkyxx33izvkhbwmindy0zjjk28hih1a9l2jmx";
          };
        }];
      };
    };

    system.userActivationScripts.cleanupZgen = "rm -fv $XDG_CACHE_HOME/zsh/*";
  };
}
