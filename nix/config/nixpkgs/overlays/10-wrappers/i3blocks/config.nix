{ writeScript, colors, xorg, libnotify, maim, xclip }:
let
  audio = writeScript "audio" (import ./scripts/audio.nix {});
  brightness = writeScript "brightness" (
    import ./scripts/brightness.nix {
      inherit xorg;
    }
  );
  bluetooth-headset = writeScript "bluetooth-headset" (import ./scripts/bluetooth-headset.nix {});
  microphone = writeScript "audio" (import ./scripts/microphone.nix {});
  language = writeScript "audio" (import ./scripts/language.nix {});
in
''
  full_text=|
  align=center
  separator=false
  separator_block_width=5

  [seperator]

  [headset]
  interval=5
  command=${bluetooth-headset} "00:1B:66:83:D1:86"
  label=
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

  [brightness]
  command=${brightness}
  color=${colors.foreground}
  interval=5
  label=
  interval=5

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
