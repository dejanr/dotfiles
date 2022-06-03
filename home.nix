{ pkgs, lib, config, writeScript, ... }:

let
  sources = import ./nix;
  pkgs = import sources.nixpkgs {};

  imports = [
    ./modules/shell/bash
  ];

  homeDir = builtins.getEnv "HOME";

  pyPkgs = with pkgs; [
    python37
    python37Packages.python-language-server
    python37Packages.virtualenv
  ];

  t = import ./nix/config/nixpkgs/overlays/20-scripts/t/default.nix {
    inherit (pkgs);
    pkgs = pkgs;
  };

  bashScripts = with pkgs; [
    t
  ];
in
{
  inherit imports;

  home.username = builtins.getEnv "USER";
  home.homeDirectory = homeDir;
  home.stateVersion = "21.03";

  home.packages = with pkgs; [
    awscli
    awslogs
    bat
    cocoapods
    direnv
    delta
    gitAndTools.diff-so-fancy
    exiftool
    exa
    fd
    ffmpeg
    fzf
    gnupg
    htop
    jq
    kubectl
    kubectx
    kustomize
    niv
    nixfmt
    opam
    pgformatter
    ripgrep
    tree

    tmux

    vim
    wget
    haskellPackages.gitHUD
  ] ++ bashScripts;

  home.sessionVariables = {
    EDITOR = "vim";
    JAVA_HOME = "${pkgs.openjdk8}/zulu-8.jdk/Contents/Home/";
  };

  home.sessionPath = [ "/usr/local/bin" "${homeDir}/.bin" "${homeDir}/.local/bin"];

  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
  };

  programs.direnv.enableZshIntegration = true;

  programs.git = {
    enable = true;
    package = pkgs.git;
    userName = "Dejan Ranisavljevic";
    userEmail = "dejan@ranisavljevic.com";

    extraConfig = {
      github.user = "dejanr";
      pull.rebase = true;
    };
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

  };

  programs.home-manager.enable = true;
}
