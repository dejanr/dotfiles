{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.home.cli.zsh;
  darwinPath = "export PATH=node_modules/.bin:~/.bun/bin:$GOPATH/bin:$PATH";
  nixosPath = "export PATH=node_modules/.bin:~/.bun/bin:$GOPATH/bin:/run/wrappers/bin:/run/current-system/sw/bin:$PATH";
in
{
  options.modules.home.cli.zsh = {
    enable = mkEnableOption "zsh";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.zsh
      pkgs.zoxide
      pkgs.fd
      pkgs.eza
    ];

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ ];
    };

    programs.fd = {
      enable = true;
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      # The command that gets executed as the default source for fzf when running.
      defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
      # Extra command line options given to fzf by default.
      defaultOptions = [
        "--height 50%"
        "--layout=default"
        "--border"
        "--color=hl:#2dd4bf"
      ];
      # The command that gets executed as the source for fzf for the CTRL-T keybinding.
      fileWidgetCommand = "rg --files --no-ignore --hidden --follow --glob '!.git/*'";
      fileWidgetOptions = [ "--preview 'bat --color=always -n --line-range :500 {}'" ];
      # The command that gets executed as the source for fzf for the ALT-C keybinding.
      changeDirWidgetCommand = "fd --type=d --hidden --strip-cwd-prefix --exclude .git";
      changeDirWidgetOptions = [ "--preview 'eza --icons=always --tree --color=always {} | head -200'" ];
    };

    programs.zsh = {
      enable = true;

      # directory to put config files in
      dotDir = "${config.home.homeDirectory}/.config/zsh";

      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      # .zshrc
      initContent =
        let
          linuxExports = ''
            ${nixosPath}
          ''
          + optionalString (config.modules.home.secrets.agenix.enable or false) ''
            # export ANTHROPIC_API_KEY=$(cat ${config.age.secrets.anthropic_api_key.path})
            export DEEPSEEK_API_KEY=$(cat ${config.age.secrets.deepseek_api_key.path})
            export GROQ_API_KEY=$(cat ${config.age.secrets.groq_api_key.path})
            export ELEVENLABS_API_KEY=$(cat ${config.age.secrets.elevenlabs_api_key.path})
            export EXA_API_KEY=$(cat ${config.age.secrets.exa_api_key.path})
          '';
          darwinExports = ''
            ${darwinPath}
          '';
        in
        ''
          if [[ -n $SSH_CONNECTION ]]; then
            PROMPT="%F{blue}%n@%m %F{white}%~%b "$'\n'"%(?.%F{white}λ%b.%F{red}λ) %f"
          else
            PROMPT="%F{white}%~%b "$'\n'"%(?.%F{white}λ%b.%F{red}λ) %f"
          fi

          ${if pkgs.stdenv.isDarwin then darwinExports else linuxExports}

          if [ -f /opt/homebrew/bin/brew ]; then
              eval "$(/opt/homebrew/bin/brew shellenv)"
          fi

          export PASSWORD_STORE_DIR="$XDG_DATA_HOME/password-store";
          export ZK_NOTEBOOK_DIR="~/stuff/notes";
          bindkey -e
          bindkey '^ ' autosuggest-accept
          bindkey '^R' history-incremental-search-backward
          bindkey '^[[7~' beginning-of-line                               # Home key
          bindkey '^[[H' beginning-of-line                                # Home key
          if [[ "''${terminfo[khome]}" != "" ]]; then
              bindkey "''${terminfo[khome]}" beginning-of-line                # [Home] - Go to beginning of line
          fi
          bindkey '^[[8~' end-of-line                                     # End key
          bindkey '^[[F' end-of-line                                      # End key
          if [[ "''${terminfo[kend]}" != "" ]]; then
              bindkey "''${terminfo[kend]}" end-of-line                       # [End] - Go to end of line
          fi
          bindkey '^[[2~' overwrite-mode                                  # Insert key
          bindkey '^[[3~' delete-char                                     # Delete key
          bindkey '^[[C'  forward-char                                    # Right key
          bindkey '^[[D'  backward-char                                   # Left key
          bindkey '^[[5~' history-beginning-search-backward               # Page up key
          bindkey '^[[6~' history-beginning-search-forward                # Page down key
          # Navigate words with ctrl+arrow keys
          bindkey '^[Oc' forward-word                                     #
          bindkey '^[Od' backward-word                                    #
          bindkey '^[[1;5D' backward-word                                 #
          bindkey '^[[1;5C' forward-word                                  #
          bindkey '^H' backward-kill-word                                 # delete previous word with ctrl+backspace
          bindkey '^[[Z' undo                                             # Shift+tab undo last action
          # Theming section
          autoload -U colors
          colors

          edir() { tar -cz $1 | age -p > $1.tar.gz.age && rm -rf $1 &>/dev/null && echo "$1 encrypted" }
          ddir() { age -d $1 | tar -xz && rm -rf $1 &>/dev/null && echo "$1 decrypted" }

          ## case-insensitive (uppercase from lowercase) completion
          zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

          HISTFILE="$HOME/.history"
          HISTSIZE=10000000
          SAVEHIST=10000000
          setopt BANG_HIST                 # Treat the '!' character specially during expansion.
          setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
          setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
          setopt SHARE_HISTORY             # Share history between all sessions.
          setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
          setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
          setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
          setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
          setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
          setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
          setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
          setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
          setopt HIST_BEEP                 # Beep when accessing nonexistent history.
          setopt hist_ignore_all_dups
          setopt hist_ignore_space
        '';

      localVariables = {
        WORDCHARS = "*?_-.[]~=&;!#$%^(){}<>";
        HISTORY_SUBSTRING_SEARCH_PREFIXED = "1";
        HISTORY_IGNORE_ALL_DUPS = "1";
      };

      # basically aliases for directories:
      # `cd ~dots` will cd into ~/.config/nixos
      dirHashes = {
        dots = "$HOME/.config/nixos";
        stuff = "$HOME/stuff";
        media = "/run/media/$USER";
        junk = "$HOME/stuff/other";
      };

      # Tweak settings for history
      history = {
        save = 1000;
        size = 1000;
        path = "$HOME/.cache/zsh_history";
      };

      # Set some aliases
      shellAliases = {
        c = "clear";
        mkdir = "mkdir -vp";
        rm = "rm -rifv";
        mv = "mv -iv";
        cp = "cp -riv";
        icdiff = "icdiff -N";
        cat = "bat --paging=never --style=plain";
        tree = "eza --tree";
        nd = "nix develop -c $SHELL";

        e = "nvim";
        vi = "nvim";
        vim = "nvim";

        l = "eza -a";
        ll = "eza -la";
        ls = "eza -a";

        du = "du -hc";

        gd = "git diff";
        gp = "git push";
        gc = "git commit";
        gca = "git commit -a";
        gco = "git checkout";
        gb = "git branch";
        gs = "clear; git rev-parse --git-dir >/dev/null 2>&1 && git status -sb";
        grm = "git status | grep deleted | awk '{print $3}' | xargs git rm";

        timestamp = "date +%s";

        passgen = "date +%s | shasum | base64 | head -c 8 | pbcopy | echo 'Password saved in clipboard'";

        lmk = "notify-send 'Something happened!'";

        run-last-history-in-vimux = "history | grep 'clear;' | grep -v 'grep clear;' | sort -n -r | head -n 1 | cut -d';' -f2- | xargs -I {} tmux send-keys -t 0 Escape \":lua require('nvimux').prompt_command()\" Enter \"clear; {}\" Enter ";
      };

      # Source all plugins, nix-style
      plugins = [ ];
    };
  };
}
