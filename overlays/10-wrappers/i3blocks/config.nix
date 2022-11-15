{ writeScript, colors, xorg, libnotify, maim, xclip }:
let
  brightness = writeScript "brightness" (
    import ./scripts/brightness.nix {
      inherit xorg;
    }
  );
  bluetooth-headset = writeScript "bluetooth-headset" (import ./scripts/bluetooth-headset.nix {});
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
  command=${bluetooth-headset} "14:3F:A6:A3:47:F3"
  label=
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
