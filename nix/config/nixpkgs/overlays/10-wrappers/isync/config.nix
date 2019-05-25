{ }:

''
MaildirStore local
Path ~/mail/
Inbox ~/mail/INBOX
SubFolders Verbatim

IMAPAccount ranisavljevic
Host imap.gmail.com
User dejan@ranisavljevic.com
PassCmd "pass imap.gmail.com/dejan@ranisavljevic.com"
SSLType IMAPS
CertificateFile /etc/ssl/certs/ca-certificates.crt

IMAPStore ranisavljevic-remote
Account ranisavljevic

Channel sync-ranisavljevic-inbox
Master :ranisavljevic-remote:"Inbox"
Slave :local:ranisavljevic/inbox
Create Both
SyncState *

Channel sync-ranisavljevic-sent
Master :ranisavljevic-remote:"[Gmail]/Sent Mail"
Slave :local:ranisavljevic/sent
Create Both
SyncState *

Channel sync-ranisavljevic-drafts
Master :ranisavljevic-remote:"[Gmail]/Drafts"
Slave :local:ranisavljevic/drafts
Create Both
SyncState *

Channel sync-ranisavljevic-trash
Master :ranisavljevic-remote:"[Gmail]/Trash"
Slave :local:ranisavljevic/trash
Create Both
SyncState *

Channel sync-ranisavljevic-all
Master :ranisavljevic-remote:"[Gmail]/All Mail"
Slave :local:ranisavljevic/all
Create Both
SyncState *

Group sync-ranisavljevic
Channel sync-ranisavljevic-inbox
Channel sync-ranisavljevic-sent
Channel sync-ranisavljevic-drafts
Channel sync-ranisavljevic-trash
Channel sync-ranisavljevic-all
''

# vim:ft=mbsyncrc
