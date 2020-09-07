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
        htop
        tldr
        tree
      ];

      home.programs.zsh = {
        enable = true;
        enableCompletion = true;

        oh-my-zsh = {
          enable = true;
          plugins = [ "dotenv emacs man fasd fd gitfast tmux" ];
          theme = "robbyrussell";
        };

        shellAliases = {
          # cd
          ".." = "cd ..";

          vi = "vim";
          vim = "vim";
          e = "emacsclient -t";
          em = "emacsclient -c";
          dig = "dig +short +noshort";

          # vim / tmux
          run-last-history-in-vimux =
            "history | grep 'clear;' | grep -v 'grep clear;' | sort -n -r | head -n 1 | cut -d';' -f2- | xargs -i tmux send-keys -t 0 Escape :VimuxPromptCommand Enter 'clear; {}' Enter";

          # pdf
          pdf = "zathura";

          # pager
          less = "less -R";
          more = "more -R";

          # ls - general use
          ls = "exa"; # ls
          l = "exa -lbF --git"; # list, size, type, git
          ll = "exa -lbGF --git"; # long list
          llm =
            "exa -lbGF --git --sort=modified"; # long list, modified date sort
          la =
            "exa -lbhHigUmuSa --time-style=long-iso --git --color-scale"; # all list
          lx =
            "exa -lbhHigUmuSa@ --time-style=long-iso --git --color-scale"; # all + extended list

          # ls - speciality views
          lS = "exa -1"; # one column, just names
          lt = "exa --tree --level=2"; # tree       la = "ls $LS_OPTIONS -A";

          # general
          du = "du -hc";
          c = "clear";

          # git
          gd = "git_diff";
          gp = "git push";
          gc = "git commit";
          gca = "git commit -a";
          gco = "git checkout";
          gb = "git branch";
          gbda =
            "git branch --merged master | grep -v master | xargs -r git branch -d";
          gs = "clear;git status -sb";
          grm = "git status | grep deleted | awk '{print $3}' | xargs git rm";
          gpom = "git push origin HEAD:refs/for/master";
          gitv = "vim -c 'Gitv' .";

          vnc-server =
            "x11vnc -repeat -forever -noxrecord -noxdamage -rfbport 5900";
          vnc = "vncviewer −FullscreenSystemKeys -MenuKey F1";

          # wget as regular browser
          wgets =
            "wget --referer='http://www.google.com' --user-agent='Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6' --header='Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5' --header='Accept-Language: en-us,en;q=0.5' --header='Accept-Encoding: gzip,deflate' --header='Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7' --header='Keep-Alive: 300'";

          # get current timestamp
          timestamp = "date +%s";

          lmk = "notify-send 'Something happened!'";
          open = "xdg-open &>/dev/null";
        };

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
  };
}
