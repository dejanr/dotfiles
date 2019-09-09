{ config, pkgs, ... }:

# Pass store and gpg setup
#
# On fresh install we have to create gpg key pass store
#
# $ gpg --full-gen-key
#
# And then initialize password store:
#
# $ pass init gpg-id
#
# Then we have to add password for every imap account
#
# $ pass add imap.gmail.com/email@dot.com

{
  environment.systemPackages = with pkgs; [
    neomutt # A small but very powerful text-based mail client
    msmtp # Simple and easy to use SMTP client with excellent sendmail compatibility
    isync # Free IMAP and MailDir mailbox synchronizer
    notmuch # Mail indexer
    khard # Console carddav client
    mu
    ripmime # Attachment extractor for MIME messages
    w3m # A text-mode web browser
    #vdirsyncer # Synchronize calendars and contacts
    urlscan # Mutt and terminal url selector (similar to urlview)
    pass # Stores, retrieves, generates, and synchronizes passwords securely
    qtpass # gui for pass

    # overlay scripts
    mutt-openfile # Script for openning files inside neomutt
    mutt-openimage # Script for opening images inside neomutt
    mutt-sync # Script for syncing all mailboxes
  ];

  services.dovecot2 = {
    enable = true;
    enablePop3 = false;
    enableImap = true;
    mailLocation = "maildir:~/Mail:LAYOUT=fs";
  };

  # dovecot has some helpers in libexec (namely, imap).
  environment.pathsToLink = [ "/libexec/dovecot" ];
}
