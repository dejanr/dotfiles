{} :

''
text/plain; $EDITOR %s;
text/html; mutt-openfile %s;
text/html; w3m -I %{charset} -T text/html; copiousoutput;
image/*; mutt-openimage %s; copiousoutput
video/*; setsid mpv --quiet %s &; copiousoutput
application/pdf; mutt-openfile %s;
application/pgp-encrypted; gpg -d '%s'; copiousoutput;

# HTML
text/html; w3m -I %{charset} -T text/html; copiousoutput;

# Unidentified files
application/octet-stream; $EDITOR %s;
''
