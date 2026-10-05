# tmux hyperlink hover

Local patch for tmux 3.6a, applied by `overlays/90-apps/default.nix`.

```tmux
set -g mouse on
set -g mouse-hyperlink-hover on
```

The new session option defaults to off. The Home Manager tmux configuration enables it with `set -gq`, so an older running server can still reload the configuration without an unknown-option error.

With Ctrl+Shift held (without Alt/Meta), moving onto an OSC 8 hyperlink shows a hand. Moving off it resets the pointer. Existing click bindings and application mouse forwarding are unchanged. The patch runs inside the tmux server, without per-event shell commands or a local routing daemon.

The server requests all-motion mouse reporting and checks the pane's hyperlink grid using tmux's existing coordinate and hyperlink helpers. OSC 22 pointer commands go through the owning client's TTY output buffer, including through SSH. State is per client; another attached terminal's pointer is unaffected. Each reported hover reasserts the shape with `default` followed by `pointer`: Ghostty can reset its visible cursor on modifier changes without updating its cached OSC 22 shape.

Pointer state resets on movement away, reported keyboard/focus events, disabling either option, switching windows/sessions, entering copy mode/prompts/popups, and detach. Detach restores a text cursor. Read-only clients do not get hover feedback.

## Boundaries

- Requires an OSC 22-capable terminal. Verified with Ghostty 1.3.1 and Kitty 0.46.2 under X11, locally and through loopback SSH.
- The terminal must forward Ctrl+Shift file clicks and mouse motion. Ghostty's `mouse-shift-capture = always` and Kitty's grabbed mappings provide this; the [terminal routing patches](../terminal-links/README.md) keep HTTP/HTTPS clicks local.
- Feedback is **cell-motion driven**. Pressing/releasing modifiers without crossing a terminal-cell boundary cannot reliably update tmux. Ghostty may change the cursor itself in the meantime. No timer or modifier polling is added.
- Hover recognizes OSC 8 hyperlinks, not terminal-detected paths or URL regexes. It does not validate file existence or schemes; the file opener still ignores non-file links.
- Hover is disabled in tmux pane modes, prompts and overlays. Native terminal scrollback is outside tmux's control.
- Enabling the option adds mouse-motion traffic over SSH even away from links.
- This owns the client's pointer while hovering; it does not save/restore custom pointer shapes set by application passthrough. Screen content/layout changes without mouse movement may leave feedback stale until the next reported event.
- Wayland, nested tmux, mosh and macOS have not been tested.

## Build and checks

From the repository root, with the new files tracked by Git:

```sh
nix build --out-link /tmp/tmux-hover .#nixosConfigurations.omega.pkgs.tmux
python3 overlays/90-apps/tmux/test_hover.py /tmp/tmux-hover/bin/tmux
```

The Python standard-library test uses isolated sockets and PTY clients. It checks opt-in behavior, modifier/link boundaries, per-client isolation, unchanged click metadata, application motion forwarding, reset paths, read-only clients and detach cleanup. It does not require a display or change existing sessions.

Separate GUI probes compared actual XFixes cursor images in Ghostty and Kitty, both locally and over SSH. They checked hand/reset transitions and modifier re-entry across cells, then clicked a file URL containing spaces and an apostrophe. All four cases reused the correct Neovim at line 49, column 2, without changing another session's editor. Modifier re-entry within the same Ghostty cell did not update the pointer, as noted above.

Rebuilding installs the executable but does **not** upgrade an existing tmux server. The patched server must run on the tmux host (remote host for SSH). Finish existing sessions normally or use a separate socket to try it; do not kill active sessions to apply the patch. Check the connected server with:

```sh
tmux show-options -gv mouse-hyperlink-hover
```

An unknown-option error means that server is still unpatched. To disable hover on a patched server without affecting click routing:

```sh
tmux set-option -g mouse-hyperlink-hover off
```
