{ writeScript, colors, xorg, libnotify, maim, xclip }:
let
  bluetooth-headset = writeScript "bluetooth-headset" (import ./scripts/bluetooth-headset.nix { });
  language = writeScript "audio" (import ./scripts/language.nix { });
  dejli-script = writeScript "audio" (import ./scripts/dejli-script.nix { });
in
''
  full_text=|
  align=center
  separator=false
  separator_block_width=5

  [seperator]

  [dejli-screenshot]
  interval=5
  command=${dejli-script} "dejli-screenshot" "/tmp/dejli-screenshot.pid" "📸 screenshot"

  [seperator]

  [dejli-audio]
  interval=5
  command=${dejli-script} "dejli-audio" "/tmp/dejli-audio.pid" "🎙️ audio"

  [seperator]

  [dejli-gif]
  interval=5
  command=${dejli-script} "dejli-gif" "/tmp/dejli-gif.pid" "◯ gif"

  # [seperator]
  #
  # [bluetooth-headset]
  # interval=5
  # command=${bluetooth-headset} "14:3F:A6:A3:47:F3"
  # label=
  # color=${colors.foreground}

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
