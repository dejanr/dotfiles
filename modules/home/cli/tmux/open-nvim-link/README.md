# tmux Neovim file opener

The same executable supports two callers:

```sh
tmux-open-nvim-link PANE LINK
tmux-open-nvim-link --local FILE_OR_URL
```

The pane-aware mode is used by tmux's Ctrl+Shift-click and plain-click bindings. It resolves relative paths against the clicked pane and reuses a Neovim in the same session, or creates a Neovim window there. Non-file hyperlinks are ignored.

The file-opening behavior is the same locally and over SSH: the terminal forwards file clicks to tmux, and the handler runs on the tmux host. HTTP/HTTPS clicks instead use the local terminal's normal browser opener, including links displayed by a remote session. The [terminal routing patches](../../../../../overlays/90-apps/terminal-links/README.md) provide this split for Ctrl+Shift-click without changing link schemes or adding an SSH routing service.

Install the patched terminal and its settings on the machine running the terminal, and load this tmux configuration on each tmux host. Ghostty uses `mouse-shift-capture = always`; Kitty's grabbed Ctrl+Shift mappings handle web links locally and pass other clicks through. Ghostty's setting also changes Shift-selection behavior in other mouse-reporting applications. The externally installed macOS Ghostty is not patched by the Nix overlay.

The local mode is used by the Linux desktop entry, with `Terminal=false` and `%u` to preserve file URLs and line fragments. It does not require inherited `TMUX` or `TMUX_PANE`. It discovers Neovim sockets and uses each editor's tmux socket explicitly, including non-default sockets. Relative paths resolve against the selected editor's working directory.

If multiple tmux Neovim editors are running, local mode reports an error rather than guessing. If none is running, it creates a Neovim window only when the default tmux server has exactly one session. It does not launch a new external terminal. Local-mode errors go to stderr and a Linux desktop notification.

Enable system text/code-file associations with `modules.home.cli.tmux.fileOpener.enable = true` (enabled on `framework`). Browser, image, and directory associations are unchanged. This also affects opening these text/code files from a file manager, not just Ghostty.

Supported locations include relative paths, absolute paths, `~/…`, local `file://` URLs, `:line[:column]`, and `#Lline[Ccolumn]`. Links are interpreted on the tmux host. Desktop-opener calls should use absolute `file://` destinations; raw relative destinations are not reliably normalized by the system opener.

Remote-host file URLs and other schemes are rejected in local mode. The local desktop opener does not infer SSH context. Terminal clicks inside tmux use pane-aware mode instead.

After applying the terminal settings locally and reloading tmux on the target host, print a hyperlink inside tmux and Ctrl+Shift-click its label:

```sh
printf '\e]8;;file:///etc/hosts#L1\e\\Open hosts on this tmux host\e]8;;\e\\\n'
```

For file opening, tmux needs an actual OSC 8 hyperlink, not just a path recognized by the terminal. The binding applies in normal pane mode; tmux copy-mode and the terminal's own scrollback are not covered.

The [tmux hover patch](../../../../../overlays/90-apps/tmux/README.md) adds a hand pointer when Ctrl+Shift is held while moving across hyperlink cells. It requires a newly started patched tmux server on the tmux host, not just a config reload. Modifier-only changes and movement within one terminal cell are not reliably reported to tmux.

Run checks:

```sh
cd modules/home/cli/tmux/open-nvim-link
go test ./...
go vet ./...
```

Integration tests use isolated tmux servers and headless Neovim. On Linux with `gio`, they also exercise a temporary desktop association through the actual system opener, preserving `#L49C2` and reusing the existing editor. They do not modify the user's sessions or MIME defaults.
