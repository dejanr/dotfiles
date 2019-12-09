{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
      fzf # A command-line fuzzy finder written in Go
      powerline-fonts # Pre-patched and adjusted fonts for usage with the Powerline plugin.
      any-nix-shell
  ];

  programs.zsh = {
    autosuggestions.enable = true;
    enable = true;
    shellAliases = {
      gs = "clear; git status -sb";
    };
    enableCompletion = true;
    histSize = 9999;
    syntaxHighlighting = {
      enable = true;
      highlighters = [ "main" "brackets" "pattern" "root" "line"];
    };
    vteIntegration = true;

    loginShellInit = ''
      eval "$(direnv hook zsh)"
    '';

    promptInit = ''
      function spaceship_nix_shell(){
        if [[ -n "$IN_NIX_SHELL" ]]; then
          spaceship::section "green" "nix-shell"
        fi
      }

      export SPACESHIP_PROMPT_ORDER=(
        user          # Username section
        dir           # Current directory section
        host          # Hostname section
        git           # Git section (git_branch + git_status)
        exec_time     # Execution time
        line_sep      # Line break
        jobs          # Background jobs indicator
        exit_code     # Exit code section
        char          # Prompt character
      )

      export SPACESHIP_RPROMPT_ORDER=(
        nix_shell vi_mode
      )

      export SPACESHIP_CHAR_SYMBOL="λ "
      export SPACESHIP_CHAR_COLOR_SUCCESS=white

      any-nix-shell zsh --info-right | source /dev/stdin
    '';
  };

  programs.zsh.ohMyZsh = {
    enable = true;
    theme = "spaceship";
    plugins = [
      "docker"
      "extract"
      "vi-mode"
      "git"
      "gitfast"
      "git-extras"
      "httpie"
      "systemd"
      "sudo"
      "tig"
      "tmux"
      "nix"
    ];
    customPkgs = with pkgs; [
      spaceship-prompt #  A Zsh prompt for Astronauts
      nix-zsh-completions #	ZSH completions for Nix, NixOS, and NixOps
      fzf-zsh #	ZSH completions for Nix, NixOS, and NixOps
      zsh-nix-shell
    ];
  };

  users.users.dejanr.shell = "/run/current-system/sw/bin/zsh";
}
