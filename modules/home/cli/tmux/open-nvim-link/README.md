# tmux Neovim file opener

The same executable supports two callers:

```sh
tmux-open-nvim-link PANE LINK
tmux-open-nvim-link --local FILE_OR_URL
```

The pane-aware mode is used by tmux's plain-click binding. It resolves relative paths against the clicked pane and reuses a Neovim in the same session, or creates a Neovim window there. Non-file hyperlinks are ignored.

The local mode is used by the Linux desktop entry, with `Terminal=false` and `%u` to preserve file URLs and line fragments. It does not require inherited `TMUX` or `TMUX_PANE`. It discovers Neovim sockets and uses each editor's tmux socket explicitly, including non-default sockets. Relative paths resolve against the selected editor's working directory.

If multiple tmux Neovim editors are running, local mode reports an error rather than guessing. If none is running, it creates a Neovim window only when the default tmux server has exactly one session. It does not launch a new external terminal. Local-mode errors go to stderr and a Linux desktop notification.

Enable system text/code-file associations with `modules.home.cli.tmux.fileOpener.enable = true` (enabled on `framework`). Browser, image, and directory associations are unchanged. This also affects opening these text/code files from a file manager, not just Ghostty.

Supported locations include relative paths, absolute paths, `~/…`, local `file://` URLs, `:line[:column]`, and `#Lline[Ccolumn]`. For Ghostty's native Ctrl+Shift-click, use an absolute `file://` destination; the link label can remain a relative path. Raw relative hyperlink destinations are not reliably normalized by the system opener.

Remote-host file URLs and other schemes are rejected in local mode. SSH routing is not implemented. Future routing should use a separate, explicit scheme containing a configured host alias and tmux context, rather than interpreting ordinary local file URLs as remote commands.

Run checks:

```sh
cd modules/home/cli/tmux/open-nvim-link
go test ./...
go vet ./...
```

Integration tests use isolated tmux servers and headless Neovim. On Linux with `gio`, they also exercise a temporary desktop association through the actual system opener, preserving `#L49C2` and reusing the existing editor. They do not modify the user's sessions or MIME defaults.
