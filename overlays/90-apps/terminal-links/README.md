# Local web links, tmux-side file links

For Ctrl+Shift-click in mouse-captured panes:

- HTTP/HTTPS links use the **local terminal's normal URL opener**, even over SSH.
- File hyperlinks continue to tmux's pane-aware Neovim handler on the tmux host.
- Other schemes are not enabled by these changes; the file handler ignores them.

This requires terminal-side routing. A remote tmux process cannot launch the local browser through an ordinary SSH connection. No remote `xdg-open`, clipboard bridge, custom URL scheme, or escape sequence that launches URLs is introduced. Opening still requires an actual local click.

## Integration

`overlays/90-apps/default.nix` patches Ghostty 1.3.1 and Kitty 0.46.2.

**Ghostty:** while mouse reporting is active, Ctrl+Shift can recognize HTTP/HTTPS links locally, both OSC 8 links and regex-detected URLs. Non-web OSC 8 destinations cannot fall back to a URL-looking label. Other modifier combinations retain their existing behavior. `mouse-shift-capture = always` remains necessary to forward file clicks. Native link hover takes precedence over application pointer-shape updates.

**Kitty:** `mouse_handle_click web-link-press` consumes presses over HTTP/HTTPS links; `mouse_handle_click web-link` opens them on release. For other destinations these actions return Kitty's passthrough result so tmux receives the original mouse events. The normal URL opener, hyperlink confirmation policy, and existing URL callback are preserved. Pointer updates recheck native URL hover so tmux resetting its file pointer does not erase a web-link hand cursor.

The two Kitty mappings live in `modules/home/gui/kitty/config.nix`. Ungrabbed mappings are unchanged. The [tmux hover patch](../tmux/README.md) still supplies hover feedback for file hyperlinks; no URL-opening logic is added to tmux or its Go handler.

## Deployment

Install the patched terminal package and settings on the **local terminal host**, then launch a new terminal process. Rebuilding only the remote host does not change the terminal running on your laptop. The remote host continues to need the tmux click bindings and file handler (and the patched tmux server for file hover).

The Nix Ghostty package is used on Linux. The existing Darwin module uses an externally installed Ghostty (`package = null`), so this overlay does not patch that macOS application. These changes have been verified under Linux/X11, not Wayland or macOS.

## Regression checks

With the new files tracked by Git, build the packages from the repository root:

```sh
nix build --out-link /tmp/ghostty-web .#nixosConfigurations.omega.pkgs.ghostty
nix build --out-link /tmp/kitty-web .#nixosConfigurations.omega.pkgs.kitty
nix build --out-link /tmp/tmux-hover .#nixosConfigurations.omega.pkgs.tmux
python3 overlays/90-apps/terminal-links/test_routing.py \
  --ghostty /tmp/ghostty-web/bin/ghostty \
  --kitty /tmp/kitty-web/bin/kitty \
  --tmux /tmp/tmux-hover/bin/tmux
```

Requires Linux, Xvfb, xdotool, dbus-run-session, OpenSSH client/server, Neovim, and `tmux-open-nvim-link` on PATH (or pass `--nvim` and `--opener`). The Python test creates private terminal environments, tmux sockets, SSH keys and a loopback-only SSH server. A recording `xdg-open` replaces the browser only inside those environments; local and server-side invocations carry different markers. No real browser is launched and no user MIME settings or SSH authorization files are changed.

The four terminal/transport cases check OSC 8 HTTP/HTTPS links, plain-text URLs, uppercase schemes, query/fragment preservation, unsupported schemes, and file hyperlinks with URL-looking labels. Files with spaces and apostrophes must reuse the right Neovim at line 49, column 2, without touching another session. Unpatched Ghostty fails on the first HTTPS click. `--keep` retains isolated fixtures/logs for debugging.

Additional XFixes image probes verified web/file hand cursors, transitions between file and plain-text web links, and pointer reset in both terminals locally and over SSH.
