{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neomutt
    msmtp
    isync
    notmuch
    khard
    mu
    ripmime
    w3m
    vdirsyncer
    urlscan
    pass
    qtpass

    # overlay scripts
    mutt-openfile
    mutt-openimage
    mutt-sync
  ];

  services.dovecot2 = {
    enable = true;
    enablePop3 = false;
    enableImap = true;
    mailLocation = "maildir:~/Mail:LAYOUT=fs";
  };

  # dovecot has some helpers in libexec (namely, imap).
  environment.pathsToLink = [ "/libexec/dovecot" ];

  systemd.user.services."mutt-sync" = {
    description = "mutt sync job";
    wants = [ "notmuch.service" ];
    before = [ "notmuch.service"];
    path = [ pkgs.pass ];
    serviceConfig = {
      Restart = "no";
      ExecStart = "${pkgs.isync}/bin/mbsync -a";
    };
  };

  systemd.user.timers.mbsync = {
    description = "run mbsync job every 5 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnStartupSec="10s";
      OnUnitActiveSec ="15m";
    };
  };

  systemd.user.services."notmuch" = {
    description = "notmuch update db";
    serviceConfig = {
      Restart = "no";
      ExecStart = "${pkgs.notmuch}/bin/notmuch new";
    };
  };
}
