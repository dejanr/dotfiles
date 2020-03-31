{ pkgs, lib, ... }:

{
  imports = [
    ../common/aliases.nix
  ];

  environment.systemPackages = with pkgs; [
    fzf # A command-line fuzzy finder written in Go
    powerline-fonts # Pre-patched and adjusted fonts for usage with the Powerline plugin.
    any-nix-shell
  ];

  programs.zsh = {
    enable = true;
    autosuggestions = {
      enable = true;
    };
    enableCompletion = true;
    histSize = 9999;
    syntaxHighlighting = {
      enable = true;
      highlighters = [ "main" "brackets" "pattern" "root" "line" ];
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

      export LC_ALL=en_US.UTF-8
      export LC_CTYPE=en_US.UTF-8
      export LANG=en_US.UTF-8
      export EDITOR="vim"
      export GIT_EDITOR="vim"
      export VISUAL="vim"
      export ACK_PAGER_COLOR="less -R"
      export ALTERNATE_EDITOR="vim"
      export XDG_CONFIG_HOME=~/.config
      export TZ="Europe/Berlin"
      export npm_config_loglevel=warn # NPM log level
      export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"' # FZF default command

      export PATH="node_modules/.bin:$HOME/.npm/bin:/run/wrappers/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/local/sbin:$GOPATH/bin:$PATH"

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
      "tig"
      "tmux"
      "nix"
    ];
    customPkgs = with pkgs; [
      spaceship-prompt #  A Zsh prompt for Astronauts
      nix-zsh-completions #  ZSH completions for Nix, NixOS, and NixOps
      fzf-zsh #  ZSH completions for Nix, NixOS, and NixOps
    ];
  };

  users.users.dejanr.shell = "/run/current-system/sw/bin/zsh";
}
