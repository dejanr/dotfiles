{ colors, fonts }: ''
  smart_gaps on
  smart_borders on
  gaps inner 2
  gaps outer 1

  smart_borders on

  # Constants
  set $mod Mod4

  set $base00 #181818
  set $base01 #10151b
  set $base02 #383838
  set $base03 #585858
  set $base04 #b8b8b8
  set $base05 #d8d8d8
  set $base06 #e8e8e8
  set $base07 #f8f8f8
  set $base08 #ab4642
  set $base09 #dc9656
  set $base0A #f7ca88
  set $base0B #a1b56c
  set $base0C #86c1b9
  set $base0D #98d1ce
  set $base0E #ba8baf
  set $base0F #a16946

  set $workspace1 "1: "
  set $workspace2 "2: "
  set $workspace3 "3: "
  set $workspace4 "4: "
  set $workspace5 "5: "
  set $workspace6 "6: "
  set $workspace7 "7: "
  set $workspace8 "8: "
  set $workspace9 "9: "
  set $workspace10 "10: "
  set $workspace11 "11: "

  set $monitor1 "DispayPort-2"
  set $monitor2 "HDMI-A-0"

  # General Configuration
  font pango:PragmataPro 9
  floating_modifier $mod
  hide_edge_borders both
  new_window none

  # change container layout (stacked, tabbed, default)
  bindsym $mod+Shift+i layout stacking
  # bindsym $mod+Shift+u layout tabbed
  # bindsym $mod+Shift+y layout default

  # Window-Related Bindings
  bindsym $mod+q kill
  bindsym $mod+h focus left
  bindsym $mod+j focus down
  bindsym $mod+k focus up
  bindsym $mod+l focus right
  bindsym $mod+Shift+h move left
  bindsym $mod+Shift+j move down
  bindsym $mod+Shift+k move up
  bindsym $mod+Shift+l move right
  # small floating window, usefull for youtube or terminal indicator on top
  bindsym $mod+Shift+f fullscreen disable; floating enable; resize set 400 300; sticky enable; move window to position 2140 20
  bindsym $mod+Shift+space floating toggle
  bindsym $mod+f fullscreen toggle
  bindsym $mod+space focus mode_toggle

  bindsym $mod+Shift+r mode "  "
  mode "  " {
    bindsym h resize shrink width 10 px or 10 ppt
    bindsym j resize grow height 10 px or 10 ppt
    bindsym k resize shrink height 10 px or 10 ppt
    bindsym l resize grow width 10 px or 10 ppt
    bindsym Escape mode "default"
  }

  bindsym $mod+Escape mode "$mode_system"
  set $mode_system System:  (l)ock   log(o)ut   (s)uspend   (r)eboot   (p)oweroff
  mode "$mode_system" {
      bindsym l exec wm-lock, mode "default"
      bindsym o exec i3-msg exit, mode "default"
      bindsym s exec systemctl suspend, mode "default"
      bindsym r exec systemctl reboot, mode "default"
      bindsym p exec systemctl poweroff, mode "default"

      bindsym Return mode "default"
      bindsym Escape mode "default"
  }

  # Restart-Related Bindings
  bindsym $mod+Shift+c reload
  bindsym $mod+Shift+x restart

  # Program-Related Bindings
  bindsym $mod+Return exec kitty --start-as maximized --single-instance -d ~ &> /dev/null &
  bindsym $mod+Shift+Return exec i3-msg split toggle && kitty --start-as maximized --single-instance -d ~ &> /dev/null & && i3-msg split toggle
  bindsym $mod+d exec "rofi -show drun -modi drun,run -show-icons"
  bindsym $mod+p exec screenshot
  bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -b 'Yes, exit i3' 'i3-msg exit'"

  # Volume & Media Bindings
  bindsym XF86AudioLowerVolume exec --no-startup-id pulseaudio-ctl down
  bindsym XF86AudioRaiseVolume exec --no-startup-id pulseaudio-ctl up
  bindsym XF86AudioMute exec --no-startup-id pulseaudio-ctl mute
  bindsym XF86AudioPlay exec playerctl play-pause
  bindsym XF86AudioPause exec playerctl pause
  bindsym XF86AudioNext exec playerctl next
  bindsym XF86AudioPrev exec playerctl previous

  # Workspace-Related Bindings
  bindsym $mod+1 workspace $workspace1
  bindsym $mod+2 workspace $workspace2
  bindsym $mod+3 workspace $workspace3
  bindsym $mod+4 workspace $workspace4
  bindsym $mod+5 workspace $workspace5
  bindsym $mod+6 workspace $workspace6
  bindsym $mod+7 workspace $workspace7
  bindsym $mod+8 workspace $workspace8
  bindsym $mod+9 workspace $workspace9
  bindsym $mod+0 workspace $workspace10

  bindsym $mod+Shift+1 move container to workspace $workspace1; workspace $workspace1
  bindsym $mod+Shift+2 move container to workspace $workspace2; workspace $workspace2
  bindsym $mod+Shift+3 move container to workspace $workspace3; workspace $workspace3
  bindsym $mod+Shift+4 move container to workspace $workspace4; workspace $workspace4
  bindsym $mod+Shift+5 move container to workspace $workspace5; workspace $workspace5
  bindsym $mod+Shift+6 move container to workspace $workspace6; workspace $workspace6
  bindsym $mod+Shift+7 move container to workspace $workspace7; workspace $workspace7
  bindsym $mod+Shift+8 move container to workspace $workspace8; workspace $workspace8
  bindsym $mod+Shift+9 move container to workspace $workspace9; workspace $workspace9
  bindsym $mod+Shift+0 move container to workspace $workspace10; workspace $workspace10

  # L2
  bindsym $mod+Shift+y exec --no-startup-id input-remapper-control --command start --device "Keyboardio Atreus" --preset lineage
  bindsym $mod+Shift+u exec --no-startup-id input-remapper-control --command stop --device "Keyboardio Atreus"

  # Workspace Monitors
  workspace $workspace1 output $monitor1
  workspace $workspace2 output $monitor1
  workspace $workspace3 output $monitor1
  workspace $workspace4 output $monitor1
  workspace $workspace5 output $monitor1
  workspace $workspace6 output $monitor1
  workspace $workspace7 output $monitor1
  workspace $workspace8 output $monitor1
  workspace $workspace9 output $monitor1
  workspace $workspace10 output $monitor1
  workspace $workspace11 output $monitor2

  # Program Workspaces
  assign [class="Pronterface.py"] $workspace5
  assign [class="Cura"] $workspace5
  assign [class=".slic3r.pl-wrapped"] $workspace5
  assign [class="Slack"] $workspace10
  assign [class="discord"] $workspace7
  assign [class="Mail"] $workspace9
  assign [class="Daily"] $workspace9
  assign [class="pyfa.py"] $workspace6
  assign [class="exefile.exe"] $workspace5
  assign [title="Google Meet"] $workspace11
  assign [title="Google Calendar"] $workspace9
  assign [title="Gmail"] $workspace9
  assign [title="EVE Launcher"] $workspace4
  assign [title="Steam"] $workspace4
  assign [class="Albion-Online"] $workspace5
  assign [class="Qemu-kvm"] $workspace3
  assign [class="l2.exe"] $workspace4
  assign [class="steam_app_1426050"] $workspace5
  assign [class="steam_app_1170950"] $workspace5
  assign [class="clientloader.exe"] $workspace6
  assign [class="entropia.exe"] $workspace6

  # fix graphics glitch
  new_window none

  # Floating
  for_window [window_role="pop-up"] floating enable
  for_window [window_role="bubble"] floating enable
  for_window [window_role="task_dialog"] floating enable
  for_window [window_role="Preferences"] floating enable
  for_window [class="Albion-Online"] border normal 0
  for_window [class="Albion-Online"] border pixel 0

  for_window [class="Lxappearance"] floating enable
  for_window [class="Seahorse"] floating enable
  for_window [class="Pavucontrol"] floating enable
  for_window [class="Qalculate-gtk"] floating enable
  for_window [class=".kazam-wrapped"] floating enable
  for_window [class="Pidgin"] floating enable
  for_window [class="Pidgin"] resize set 400 600
  for_window [class="Pidgin"] move window to position 1500 50
  for_window [class="Thunar"] floating enable
  for_window [class="Thunar"] resize set 650 400
  for_window [class="Thunar"] move window to position 600 200
  for_window [class="Pcmanfm"] floating enable
  for_window [class="Pcmanfm"] resize set 1200 700
  for_window [class="Pcmanfm"] move window to position 100 300
  for_window [class="Thunderbird"] floating enable
  for_window [class="Thunderbird"] resize set 920 1060
  for_window [class="Thunderbird"] move window to position 1000 20
  for_window [class="Corebird"] floating enable
  for_window [class="Corebird"] resize set 450 1060
  for_window [class="Corebird"] move window to position 1470 18

  for_window [title="EVE - D' Zwer"] floating enable
  for_window [title="EVE - D' Zwer"] resize set 1490 1420
  for_window [title="EVE - D' Zwer"] move window to position 0 20
  for_window [title="EVE - R' Zwer"] floating enable
  for_window [title="EVE - R' Zwer"] resize set 1490 1420
  for_window [title="EVE - R' Zwer"] move window to position 0 20
  for_window [title="EVE - P' Zwer"] floating enable
  for_window [title="EVE - P' Zwer"] resize set 1490 1420
  for_window [title="EVE - P' Zwer"] move window to position 0 20
  for_window [title="EVE - hollyoake09"] floating enable
  for_window [title="EVE - hollyoake09"] resize set 1490 1420
  for_window [title="EVE - hollyoake09"] move window to position 975 20
  for_window [title="EVE - R' hollyoake"] floating enable
  for_window [title="EVE - R' hollyoake"] resize set 1490 1420
  for_window [title="EVE - R' hollyoake"] move window to position 975 20
  for_window [title="EVE - P' hollyoake"] floating enable
  for_window [title="EVE - P' hollyoake"] resize set 1490 1420
  for_window [title="EVE - P' hollyoake"] move window to position 975 20
  for_window [title="EVE - Haibu"] floating enable
  for_window [title="EVE - Haibu"] resize set 1490 1420
  for_window [title="EVE - Haibu"] move window to position 1950 20
  for_window [title="EVE - R' Haibu"] floating enable
  for_window [title="EVE - R' Haibu"] resize set 1490 1420
  for_window [title="EVE - R' Haibu"] move window to position 1950 20
  for_window [title="EVE - P' Haibu"] floating enable
  for_window [title="EVE - P' Haibu"] resize set 1490 1420
  for_window [title="EVE - P' Haibu"] move window to position 1950 20
  for_window [title="EVE - Brqa"] floating enable
  for_window [title="EVE - Brqa"] resize set 1490 1420
  for_window [title="EVE - Brqa"] move window to position 1950 20
  for_window [class="Albion-Online"] floating enable
  for_window [class="Albion-Online"] resize set 3440 1440
  for_window [class="Albion-Online"] move window to position 0 -20
  for_window [class="steam_app_1063730"] fullscreen disable
  for_window [class="steam_app_1063730"] floating enable
  for_window [class="steam_app_1063730"] resize set 3440 1420
  for_window [class="steam_app_1063730"] move window to position 0 20
  for_window [title="EVE"] floating disable
  for_window [class="steam_app_327070"] fullscreen disable
  for_window [class="steam_app_327070"] floating enable
  for_window [class="steam_app_327070"] resize set 3440 1400
  for_window [class="steam_app_327070"] move window to position 0 20
  for_window [class="Embers Adrift"] floating enable
  for_window [class="Embers Adrift"] resize set 3440 1440
  for_window [class="Embers Adrift"] move window to position 0 -20
  for_window [class="l2.exe"] floating enable
  for_window [class="l2.exe"] resize set 1920 1440
  for_window [class="steam_app_1426050"] floating disable
  for_window [class="steam_app_1426050"] resize set 3440 1420
  for_window [class="steam_app_1426050"] move window to position 0 -20
  for_window [class="steam_app_1170950"] fullscreen disable
  for_window [class="steam_app_1170950"] floating enable
  for_window [class="steam_app_1170950"] resize set 3440 1440
  for_window [class="steam_app_1170950"] move window to position 0 20
  for_window [class="entropia.exe"] floating enable
  for_window [class="entropia.exe"] move window to position 760 20
  for_window [class="clientloader.exe"] floating enable
  for_window [class="clientloader.exe"] move window to position 1300 400

  # Widow Colours
  #                         border  background text    indicator
  client.focused $base0D $base0D $base00 $base01
  client.focused_inactive $base02 $base02 $base03 $base01
  client.unfocused $base01 $base01 $base03 $base01
  client.urgent $base02 $base08 $base07 $base08

  # Bar
  bar {
    font pango: PragmataPro, FontAwesome 9
    status_command i3blocks
    position top
    strip_workspace_numbers no
    bindsym button4 nop
    bindsym button5 nop

    colors {
      separator $base03
      background $base01
      statusline $base05
      #                  border  background text
      focused_workspace  $base0C $base0D    $base00
      active_workspace   $base02 $base02    $base07
      inactive_workspace $base01 $base01    $base03
      urgent_workspace   $base08 $base08    $base07
    }
  }

  # toggle split orientation
  bindsym $mod+s split toggle

  # applications
  bindsym $mod+w exec --no-startup-id firefox -p Personal
  bindsym $mod+e exec --no-startup-id firefox -p Work
  bindsym $mod+r exec --no-startup-id kitty ranger

  # Windows switching

  bindsym $mod+a workspace back_and_forth
  bindsym Mod1+Tab focus right

  focus_follows_mouse yes
  mouse_warping output
  focus_wrapping no
  focus_on_window_activation focus
''
