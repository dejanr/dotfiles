{ writeScript, colors }:

let
  audio = writeScript "audio" (import ./scripts/audio.nix { });
  mail = writeScript "mail" (import ./scripts/mail.nix { });
  bluetooth-headset = writeScript "bluetooth-headset" (import ./scripts/bluetooth-headset.nix { });
  microphone = writeScript "audio" (import ./scripts/microphone.nix { });
  language = writeScript "audio" (import ./scripts/language.nix { });

in ''
full_text=|
align=center
separator=false
separator_block_width=5

[seperator]

[mail]
interval=5
command=${mail}
label=✉
color=${colors.foreground}

[seperator]

[headset]
interval=5
command=${bluetooth-headset} "00:1B:66:83:D1:86"
label=
color=${colors.foreground}

[seperator]

[audio]
command=${audio}
interval=5
label=
color=${colors.foreground}

[seperator]

[microphone]
command=${microphone}
interval=5
label=
color=${colors.foreground}

[seperator]

[language]
command=${language}
interval=1
label= 
color=${colors.foreground}

[seperator]

[date]
command=echo " `date +'%A ◦ %d %B ◦ %Y'`"
interval=1
label= 
color=${colors.foreground}

[seperator]

[time]
command=echo " `date +'%H:%M'`"
interval=1
label= 
color=${colors.foreground}

[seperator]
''