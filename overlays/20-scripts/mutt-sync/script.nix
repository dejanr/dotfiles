{ }:
''
  #!/usr/bin/env bash
  # Sync mail and give notification if there is a new mail.

  export DISPLAY=:0.0

  # Run mbsync. You can feed this script different settings.
  if [ $# -eq 0 ]; then
    mbsync -a
  else
    mbsync "$@"
  fi

  # Check all accounts/mailboxes for new mail. Notify if there is new content.
  for account in "$HOME/mail/"*
  do
    acc="$(echo "$account" | sed "s/.*\///")"
    messages=$(find "$account/inbox/new/" -type f -newer "$HOME/.cache/mutt-sync-lastrun" 2> /dev/null)

    for file in $messages
    do
      notify-send "✉ You've Got Mail"
    done
  done

  notmuch new 2>/dev/null

  #Create a touch file that indicates the time of the last run of mailsync
  touch "$HOME/.cache/mutt-sync-lastrun"
''
