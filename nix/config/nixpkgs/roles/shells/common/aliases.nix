{ config, pkgs, ... }:

let
  take = pkgs.writeScriptBin "take" ''
    #!/bin/sh

    mkdir -p $1;
    cd $1;
  '';
  encrypt = pkgs.writeScriptBin "encrypt" ''
    #!/bin/sh

    echo "$1" | openssl enc -pbkdf2 -a -kfile ~/.ssh/id_rsa
  '';
  decrypt = pkgs.writeScriptBin "decrypt" ''
    #!/bin/sh

    echo "$1" | openssl enc -pbkdf2 -a -kfile ~/.ssh/id_rsa -d
  '';
  generate-ssl = pkgs.writeScriptBin "generate-ssl" ''
    #!/bin/sh

    openssl genrsa -out privatekey.pem 1024 && \
    openssl req -new -key privatekey.pem -out certrequest.csr  && \
    openssl x509 -req -in certrequest.csr -signkey privatekey.pem -out certificate.pem
  '';
  nix-test = pkgs.writeScriptBin "nix-test" ''
    #!/bin/sh
    echo "Creating vm and running nixos-rebuild inside ..."
    VM=$(/run/current-system/sw/bin/nixos-rebuild --fast build-vm 2>&1 | ${pkgs.coreutils}/bin/tail -n1 | ${pkgs.gawk}/bin/awk '{ print $10 }')
    echo "$VM"
    "$VM" -m 2G,maxmem=4G -smp 4
  '';
  lb = pkgs.writeScriptBin "lb" ''
    #!/bin/sh
    mkdir -p ~/documents/logbook/
    vim -c 'cd %:p:h' ~/documents/logbook/$(date '+%Y-%m-%d').org
  '';
in
{
  environment.systemPackages = with pkgs; [
    take
    encrypt
    decrypt
    generate-ssl
    nix-test
    lb
  ];

  environment.shellAliases = {
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
}
