{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.zsh;
in {
    options.modules.zsh = { enable = mkEnableOption "zsh"; };

    config = mkIf cfg.enable {
    	home.packages = [
          pkgs.zsh
        ];

        programs.zsh = {
            enable = true;

            # directory to put config files in
            dotDir = ".config/zsh";

            enableCompletion = true;
            enableAutosuggestions = true;
            syntaxHighlighting.enable = true;

            # .zshrc
            initExtra = ''
                PROMPT="%F{white}%~%b "$'\n'"%(?.%F{white}λ%b.%F{red}λ) %f"

                if [ -f /opt/homebrew/bin/brew ]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                fi

                export PASSWORD_STORE_DIR="$XDG_DATA_HOME/password-store";
                export ZK_NOTEBOOK_DIR="~/stuff/notes";
                export DIRENV_LOG_FORMAT="";
                bindkey -e
                bindkey '^ ' autosuggest-accept
                bindkey '^R' history-incremental-search-backward
                bindkey '^[[7~' beginning-of-line                               # Home key
                bindkey '^[[H' beginning-of-line                                # Home key
                if [[ "''${terminfo[khome]}" != "" ]]; then
                    bindkey "''${terminfo[khome]}" beginning-of-line                # [Home] - Go to beginning of line
                fi
                bindkey '^[[8~' end-of-line                                     # End key
                bindkey '^[[F' end-of-line                                     # End key
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
            '';

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
                cat = "bat --paging=never --style=plain";
                tree = "eza --tree";
                nd = "nix develop -c $SHELL";

				e = "nvim -i NONE";
				vi = "nvim -i NONE";
				vim = "nvim -i NONE";
				nvim = "nvim -i NONE";

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
				gs = "clear; git status -sb";
				grm = "git status | grep deleted | awk '{print $3}' | xargs git rm";

				timestamp = "date +%s";

				passgen = "date +%s | shasum | base64 | head -c 8 | pbcopy | echo 'Password saved in clipboard'";

				lmk = "notify-send 'Something happened!'";

                run-last-history-in-vimux = "history | grep 'clear;' | grep -v 'grep clear;' | sort -n -r | head -n 1 | cut -d';' -f2- | xargs -i tmux send-keys -t 0 Escape :VimuxPromptCommand Enter 'clear; {}' Enter";
            };

            # Source all plugins, nix-style
            plugins = [
        ];
    };
};
}
