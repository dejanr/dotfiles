# Chrome profiles

Framework and Omega enable `modules.home.gui.browser.chrome`.

| Entry | Purpose |
| --- | --- |
| `chrome-personal` | Personal browser; default external-link handler |
| `chrome-work` | Work browser |
| Super+W / Super+E | New Personal / Work window in Niri and i3 |
| Google Chrome (Personal) / (Work) | Separate application-launcher entries |

Each launcher uses a separate user-data directory under
`${XDG_DATA_HOME:-$HOME/.local/share}/chrome-profiles/Personal` or `Work`.
Cookies, accounts, history, extensions, and running browser instances are independent.
External links always use Personal, even when Work was used last.

These are fresh Chrome profiles. Qutebrowser data under `~/.browser/` and existing
Chrome data under `~/.config/google-chrome/` are not moved, overwritten, or imported.
Sign in separately in each profile; use Chrome's bookmark import if needed.
Profile state stays writable and is not managed by Home Manager.

Chrome's [user-data directory documentation](https://chromium.googlesource.com/chromium/src/+/main/docs/user_data_dir.md)
describes the `--user-data-dir` isolation used here. The launchers leave the browser
sandbox enabled and do not expose remote debugging.

`checks.x86_64-linux.chrome-profiles` verifies launcher routing, URL argument
preservation, XDG/default directory handling, and default desktop entries.
`checks.x86_64-linux.framework-desktop` validates the Niri shortcuts and default browser.
