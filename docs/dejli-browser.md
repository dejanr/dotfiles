# Dejli Browser integration

## Home Manager

`modules/home/gui/browser/dejli-browser.nix` defines
`modules.home.gui.browser.dejli-browser`. It is currently disabled on all
hosts; Framework and Omega use [Chrome with separate Personal/Work profiles](chrome.md).

| Entry                                 | Purpose                                                    |
| ------------------------------------- | ---------------------------------------------------------- |
| `dejli-browser`                       | Personal profile; default external-link handler            |
| `dejli-browser-work`                  | Work profile                                               |
| Super+W / Super+E                     | `--new-window` in Personal / Work on the current workspace |
| `~/.config/dejli-browser/config.toml` | Shared Home Manager settings                               |
| `li.dej.browser.desktop`              | Personal/default desktop entry                             |
| `li.dej.browser.work.desktop`         | Work desktop entry                                         |
| `li.dej.browser`                      | Wayland app ID for both profiles                           |

## Profile compatibility

The launchers intentionally continue using the existing data/cache roots:

```text
~/.local/share/buffr-profiles/Personal/
~/.local/share/buffr-profiles/Work/
~/.cache/buffr-profiles/Personal/
~/.cache/buffr-profiles/Work/
```

## Upgrade and verify

After publishing tested changes from the fork:

```sh
nix flake update dejli-browser
nix build .#dejli-browser
nix build --no-link .#checks.x86_64-linux.framework-desktop
sudo nixos-rebuild switch --flake .#framework
```

The browser build runs its Cargo workspace tests. The Framework check validates
the Chrome Personal default and Niri shortcuts. The fork also contains Niri regressions under `tests/dejli/` for
shared-profile windows/current-workspace placement, clipboard shortcuts, and
new-tab behavior; see its fork guide for interactive-check requirements.

For local development without publishing, use an explicit temporary override:

```sh
nix build --no-write-lock-file \
  --override-input dejli-browser path:/home/dejanr/projects/dejli/browser \
  .#dejli-browser
```

Do not commit a local-path override to `flake.lock`. Keep upstream rebases and
feature commits in the browser repository; only update the source pin and
integration settings here.
