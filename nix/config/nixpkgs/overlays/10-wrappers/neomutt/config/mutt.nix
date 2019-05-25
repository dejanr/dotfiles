{ colors, fonts, mailcapFile, msmtp, isync }:

with colors;
with fonts;

''
#-------- General {{{
#------------------------
# paths
set folder = ~/mail
set message_cachedir = ~/.cache/mutt/bodies
set certificate_file = /etc/ssl/certs/ca-certificates.crt
set mailcap_path = ${mailcapFile}
set tmpdir = /tmp

# basic options
set wait_key = no
set mbox_type = Maildir
set timeout = 3
set mail_check = 0
set delete
set quit
set thorough_search
set mail_check_stats
set copy = no
set move              = no
unset confirmappend
unset move
unset mark_old
unset beep_new

# compose View Options
set envelope_from                    # which from?
set edit_headers                     # show headers when composing
set fast_reply                       # skip to compose when replying
set askcc                            # ask for CC:
set fcc_attach                       # save attachments with the body
set forward_format = "Fwd: %s"       # format of subject when forwarding
set forward_decode                   # decode when forwarding
set attribution = "On %d, %n wrote:" # format of quoting header
set reply_to                         # reply to Reply to: field
set reverse_name                     # reply as whomever it was to
set include                          # include message in replies
set forward_quote                    # include message in forwards
set editor            = "vim +/^$ ++1"
set text_flowed
unset sig_dashes                     # no dashes before sig
unset mime_forward                   # forward attachments as part of body
unset imap_passive
unset record

# status bar, date format, finding stuff etc.
set status_chars = " *%A"
set status_format = "[ Folder: %f ] [%r%m messages%?n? (%n new)?%?d? (%d to delete)?%?t? (%t tagged)? ]%>─%?p?( %p postponed )?"
set date_format = "%d.%m.%Y %H:%M"
set index_format = "[%Z] %?X?A&-? %D  %-20.20F  %s"
set sort = threads
set sort_aux = reverse-last-date-received
set uncollapse_jump
set sort_re
set reply_regexp = "^(([Rr][Ee]?(\[[0-9]+\])?: *)?(\[[^]]+\] *)?)*"
set quote_regexp = "^( {0,4}[>|:#%]| {0,4}[a-z0-9]+[>|]+)+"
set send_charset = "utf-8:iso-8859-1:us-ascii"
set charset = "utf-8"

# when composing emails, use this command to get addresses from
# the addressbook with khard first, and everything else from mu index
set query_command = "( khard email --parsable '%s' | sed -n '1!p'; mu cfind --format=mutt-ab '%s' )"

# Pager View Options
set pager_index_lines = 10
set pager_context = 3
set pager_stop
set menu_scroll
set tilde
unset markers

# email headers and attachments
ignore *
unignore from: to: cc: bcc: date: subject:
unhdr_order *
hdr_order from: to: cc: bcc: date: subject:
alternative_order text/plain text/enriched text/html
auto_view text/html

# sidebar patch config
# set sidebar_visible
set sidebar_short_path
set sidebar_folder_indent
set sidebar_width = 25
set sidebar_divider_char = " | "
set sidebar_indent_string = "  '"
set sidebar_format = "%B %* [%?N?%N / ?%S]"

# Mailboxes to show in the sidebar.
mailboxes =All
mailboxes =ranisavljevic/inbox
mailboxes ="==================="
mailboxes =ranisavljevic
mailboxes =ranisavljevic/inbox =ranisavljevic/sent =ranisavljevic/drafts =ranisavljevic/spam =ranisavljevic/all

# Account ranisavljevic

set from = "dejan@ranisavljevic.com"
set sendmail = "${msmtp}/bin/msmtp -a ranisavljevic"

# Set folders
set spoolfile = "+ranisavljevic/inbox"
set mbox = "+ranisavljevic/all"
set postponed = "+ranisavljevic/drafts"
set record = "+ranisavljevic/sent"
set trash = "+ranisavljevic/trash"

# custom signaure
# set signature = ~/.mutt/signatures/work

color status cyan default

macro index o "<shell-escape>${isync}/bin/mbsync sync-ranisavljevic<enter>" "run mbsync to sync mail for this account"

macro index,pager D \
  "<save-message>+ranisavljevic/trash<enter>"  \
  "move message to the trash"

macro index,pager A \
  "<save-message>+ranisavljevic/all<enter>"  \
  "move message to the archive"

macro index,pager I \
  "<save-message>+ranisavljevic/inbox<enter>"  \
  "move message to the inbox"


#------------------------------------------------------------
# Key Bindings
#------------------------------------------------------------

# Moving around
bind attach,browser,index       g   noop
bind attach,browser,index       gg  first-entry
bind attach,browser,index       G   last-entry
bind pager                      g   noop
bind pager                      gg  top
bind pager                      G   bottom
bind pager                      k   previous-line
bind pager                      j   next-line

# Scrolling
bind attach,browser,pager,index \CF next-page
bind attach,browser,pager,index \CB previous-page
bind attach,browser,pager,index \Cu half-up
bind attach,browser,pager,index \Cd half-down
bind browser,pager              \Ce next-line
bind browser,pager              \Cy previous-line
bind index                      \Ce next-line
bind index                      \Cy previous-line

bind pager,index                d   noop
bind pager,index                dd  delete-message

# Mail & Reply
bind index                      \Cm list-reply # Doesn't work currently

# Threads
bind browser,pager,index        N   search-opposite
bind pager,index                dT  delete-thread
bind pager,index                dt  delete-subthread
bind pager,index                gt  next-thread
bind pager,index                gT  previous-thread
bind index                      za  collapse-thread
bind index                      zA  collapse-all # Missing :folddisable/foldenable


# }}}

#-------- Color Theme {{{
#------------------------
# basic colors ---------------------------------------------------------
color normal        white           default
color error         red             default
color tilde         black           default
color message       cyan            default
color markers       red             white
color attachment    white           default
color search        brightmagenta   default
color indicator     brightblack     yellow
color tree          green          default

# sidebarh
color sidebar_new   default blue

# index ----------------------------------------------------------------

color index         red             default         "~A"    # all messages
color index         brightred       default         "~E"    # expired messages
color index         blue            default         "~N"    # new messages
color index         blue            default         "~O"    # old messages
color index         brightmagenta   default         "~Q"    # messages that have been replied to
color index         brightwhite           default         "~R"    # read messages
color index         blue            default         "~U"    # unread messages
color index         brightyellow    default         "~v"    # messages part of a collapsed thread
color index         brightyellow    default         "~P"    # messages from me
color index         red             default         "~F"    # flagged messages
color index         black           red             "~D"    # deleted messages

# message headers ------------------------------------------------------

color hdrdefault    brightgreen     default
color header        brightyellow    default         "^(From)"
color header        blue            default         "^(Subject)"

# body -----------------------------------------------------------------

color quoted        blue            default
color quoted1       cyan            default
color quoted2       yellow          default
color quoted3       red             default
color quoted4       brightred       default

color signature     brightblack     default
color bold          black           default
color underline     black           default
color normal        default         default
# }}}
''

# vim:ft=muttrc
