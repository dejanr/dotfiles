{ }:

''
  defaults
  auth on
  tls on
  tls_starttls off
  tls_trust_file /etc/ssl/certs/ca-certificates.crt
  logfile ~/.msmtp.log

  # gmail dejan@ranisavljevic.com
  account ranisavljevic
  host smtp.gmail.com
  port 465
  from dejan@ranisavljevic.com
  user dejan@ranisavljevic.com
  passwordeval "pass imap.gmail.com/dejan@ranisavljevic.com"
''

# vim:ft=msmtprc
