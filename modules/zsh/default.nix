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
                PROMPT="%F{white}%~%b "$'\n'"%(?.%F{white}λ%b.%F{red}?) %f"

                export PASSWORD_STORE_DIR="$XDG_DATA_HOME/password-store";
                export ZK_NOTEBOOK_DIR="~/stuff/notes";
                export DIRENV_LOG_FORMAT="";
                bindkey -e
                bindkey '^ ' autosuggest-accept
                bindkey '^R' history-incremental-search-backward

                edir() { tar -cz $1 | age -p > $1.tar.gz.age && rm -rf $1 &>/dev/null && echo "$1 encrypted" }
                ddir() { age -d $1 | tar -xz && rm -rf $1 &>/dev/null && echo "$1 decrypted" }
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
				open = "xdg-open &>/dev/null";
            };

            # Source all plugins, nix-style
            plugins = [
        ];
    };
};
}
