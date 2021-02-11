{ config, lib, pkgs, ... }:

{
  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.bash = {
    enable = true;

    shellAliases = {
      # cd
      ".." = "cd ..";

      vi = "vim";
      vim = "vim";
      e = "emacsclient -t";
      em = "emacsclient -c";
      dig = "dig +short +noshort";

      # vim / tmux
      run-last-history-in-vimux = "history | grep 'clear;' | grep -v 'grep clear;' | sort -n -r | head -n 1 | cut -d';' -f2- | xargs -i tmux send-keys -t 0 Escape :VimuxPromptCommand Enter 'clear; {}' Enter";

      # pdf
      pdf = "zathura";

      # pager
      less = "less -R";
      more = "more -R";

      # irc
      irc = "export TERM=screen && if tmux has-session -t irc; then tmux attach -t irc; else create-irc-session; fi";

      # ls
      l = "ls $LS_OPTIONS -CF";
      ll = "ls $LS_OPTIONS -alF";
      la = "ls $LS_OPTIONS -A";

      du = "du -hc";
      c = "clear";

      # git
      gd = "git_diff";
      gp = "git push";
      gc = "git commit";
      gca = "git commit -a";
      gco = "git checkout";
      gb = "git branch";
      gbda = "git branch --merged master | grep -v master | xargs -r git branch -d";
      gs = "clear;git status -sb";
      grm = "git status | grep deleted | awk '{print $3}' | xargs git rm";
      gpom = "git push origin HEAD:refs/for/master";
      gitv = "vim -c 'Gitv' .";

      vnc-server = "x11vnc -repeat -forever -noxrecord -noxdamage -rfbport 5900";
      vnc = "vncviewer −FullscreenSystemKeys -MenuKey F1";

      # wget as regular browser
      wgets = "wget --referer='http://www.google.com' --user-agent='Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6' --header='Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5' --header='Accept-Language: en-us,en;q=0.5' --header='Accept-Encoding: gzip,deflate' --header='Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7' --header='Keep-Alive: 300'";

      # get current timestamp
      timestamp = "date +%s";

      # generate random password and save it in clipboard
      passgen = "date +%s | shasum | base64 | head -c 8 | pbcopy | echo 'Password saved in clipboard'";

      lmk = "notify-send 'Something happened!'";
      open = "xdg-open &>/dev/null";
    };

    bashrcExtra = ''
      # prompt:start
      function restore_prompt_after_nix_shell() {
        if [ "$PS1" != "$PROMPT" ]; then
          PS1=$PROMPT
          PROMPT_COMMAND=""
        fi
      }

      PROMPT_COMMAND=restore_prompt_after_nix_shell
      if [[ $IN_NIX_SHELL != "" ]] || [[ $IN_NIX_RUN != "" ]]; then
        PROMPT="\w\[\033[0;32m\] nix-shell \$(gitHUD)\[\033[0m\] \nλ "
      else
        PROMPT="\w\[\033[0;32m\] \$(gitHUD)\[\033[0m\] \nλ "
      fi

      export PS1=$PROMPT
      # prompt:end

      export PATH="$HOME/.npm/bin:node_modules/.bin:$HOME/.bin:/run/wrappers/bin:/run//current-system/sw/bin:/usr/local/bin:/usr/local/sbin:$GOPATH/bin:$PATH"

      # NPM log level
      export npm_config_loglevel=warn

      # FZF default command
      export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'

      export TERM=xterm-256color
      export LC_ALL=en_US.UTF-8
      export LC_CTYPE=en_US.UTF-8
      export LANG=en_US.UTF-8
      export EDITOR="vim"
      export GIT_EDITOR="vim"
      export VISUAL="vim"
      export ACK_PAGER_COLOR="less -R"
      export ALTERNATE_EDITOR="vim"
      export NVM_DIR=~/.nvm
      export XDG_CONFIG_HOME=~/.config
      export TZ="Europe/Berlin"

      # setup direnv
      eval "$(direnv hook bash)"
    '';
  };
}
