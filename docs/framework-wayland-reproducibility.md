# Framework Wayland reproducibility

Research and read-only audit: 2026-10-31. No desktop configuration was activated, no services restarted, and no existing settings or state were reset during this audit.

## Recommendation

Keep NixOS + Niri + DMS for the first improvement pass. Fix ownership before changing shells, compositors, or package versions. The immediate problems are observable configuration conflicts, not evidence that NixOS or Wayland needs replacing.

Use four explicit categories:

1. **Declared configuration:** reviewed Nix/KDL/JSON in Git, deployed from the store.
2. **Generated integration files:** DMS-owned outputs, writable outside Git and reproducible from declared inputs where applicable.
3. **Runtime state:** session history, notification/clipboard data, device discovery, and other deliberately mutable data outside Git.
4. **Secrets:** externally provisioned credentials, never exported into public desktop configuration.

A reproducible desktop baseline does not require identical clipboard history, volume, or window placement. It does require an explicit policy for which GUI preferences persist and which must be promoted into declared configuration. XDG distinguishes configuration, persistent state, cache, and runtime storage for these purposes.[1]

## Implemented configuration

The migration is implemented without changing the compositor version. It has been activated on Framework; the live DMS settings are regular files outside Git, both startup preparations have completed successfully, and `desktop-config check` passes.

- `modules/home/gui/dms.nix` installs the pinned upstream Home Manager integration and the `desktop-config` command. The NixOS DMS unit remains the only startup owner.
- `hosts/framework/config/dms/preferences.nix` is the reviewed source of shell preferences and plugin declarations. The bar, control-center recording widgets, Tailscale controls, fonts, and purple shell theme are preserved without importing the full runtime dump.
- Immutable settings live under `~/.config/dms/managed/`. The systemd units run `desktop-config prepare` before Niri and DMS startup. It atomically materializes writable live JSON and clears only the known generated KDL files. This avoids handing DMS read-only files it tries to save, while making GUI preference changes temporary until explicitly reviewed into Nix.
- Niri's hand-authored bindings, window rules, and appearance live under `niri/managed/`; writable generated includes remain under `niri/dms/`. The Monstar binding is preserved. The combined declared config is validated at build time using the actual compositor package, and missing generated files are optional during first boot.
- The first preparation snapshots old settings and generated files under `~/.local/state/dms/config-backups/profile-*`, with private directory/file permissions. Existing file symlinks are replaced atomically; their checkout/store targets are never written. Unexpected symlinked output directories are refused rather than followed.
- Extra `dms/config.d` overrides are quarantined into a private backup so they cannot silently override the baseline. Plugin code is deployed declaratively, not downloaded into the source checkout.
- Only explicitly declared session preferences are merged on restart: the packaged Nightfox wallpaper, dark mode, and disabled per-monitor/per-mode wallpaper cycling. Other session data, clipboard/notification databases, histories, and device state are preserved.
- Stylix remains the external application theme owner. DMS Matugen is disabled both in the profile and in the service environment. The contradictory Home Manager common file-chooser preference is removed; NixOS's Niri-specific GTK choice remains effective.
- Recording callbacks now assign `root.recording`; plugin icons use the current `DIcon` rather than the deprecated `DankIcon` shim. The Niri IPC wrapper uses the pinned DMS executable and the helpers use the compositor's exact package. Manual Xwayland startup is removed in favor of Niri's built-in integration.
- The Dejli desktop executable remains an **explicit development override** in Framework's host configuration. Packaging that separate application is not part of this migration. This optional development integration is not reproducible on a machine without that checkout; the rest of the desktop does not depend on it for startup.

The obsolete `settings.json`, `plugin_settings.json`, and `session.json` snapshots under `hosts/framework/config/dms/` have been removed after confirming that the live settings no longer reference them. Private recovery copies remain under `~/.local/state/dms/config-backups/`; they are not configuration inputs and must not be committed.

### Apply and inspect

Build without activating:

```sh
nix build --no-link .#checks.x86_64-linux.framework-desktop
nix build --no-link .#nixosConfigurations.framework.config.system.build.toplevel
```

Activate when ready, keeping a TTY/recovery route available:

```sh
sudo nixos-rebuild switch --flake .#framework
```

The changed DMS unit may restart the shell and apply the profile; Niri is explicitly protected against restart during rebuild. Log out and back in when convenient to exercise the clean session-start path and automatic Xwayland integration.

Once installed:

```sh
desktop-config check
snapshot="$(mktemp -t desktop-preferences.XXXXXX.json)"
desktop-config export > "$snapshot"
printf 'Review preferences in %s\n' "$snapshot"
```

`check` reports differences from declared preferences; differences after a GUI experiment are expected. `export` prints only the declared settings/plugin keys and declared session preferences, not arbitrary session history. Review the result and update `preferences.nix` or `sessionPreferences` consciously. Newly introduced settings that are not already declared must be added explicitly; the export is not an automatic Git writer.

To discard experiments after reviewing them:

```sh
systemctl --user restart dms.service
```

Avoid running `desktop-config prepare` manually against the live shell: the service's `ExecStartPre` runs it while DMS is stopped. Backups are migration/recovery snapshots, not a history of every temporary preference edit.

### Verification

`checks.x86_64-linux.framework-desktop` checks a clean home, the Monstar binding, package alignment, startup ownership, and Niri syntax. It also changes a temporary preference, verifies that `desktop-config check` detects the difference, reapplies the declared profile, and asserts that launcher history survives.

During implementation, isolated migration tests and a nested Niri+DMS smoke check passed. They exercised symlink-target preservation, private backups, selective session preferences, history preservation, config-fragment quarantine, plugin loading, generated KDL, and temporary layout changes. Those local test scripts have been removed; the maintained reproducibility check is the Nix check above. The nested test did not restart host services or exercise real authentication, suspend, or screen sharing.

Physical monitor hotplug, suspend/resume, lock authentication, application file picking, and screen sharing still require validation after activation. Do not present the nested smoke check as coverage of those hardware/session workflows. Older generations from before this migration do not contain the preparation mechanism; keep the private backup when rolling back across that boundary.

## Evidence from the pre-migration audit

### What is working

- `niri validate --config ~/.config/niri/config.kdl` succeeds.
- Niri, DMS, the active portals, and cliphist are running; `systemctl --user --failed` reports no failed units.
- DMS has zero recorded service restarts in the current session.
- `dms doctor --json` reports **0 errors, 3 warnings**. The warnings concern compositor blur support, the intentionally unavailable power-profile service, and printer-management support. They are not proof of a broken session.
- The user manager has `XDG_CURRENT_DESKTOP=niri`, `XDG_SESSION_TYPE=wayland`, and a Wayland display.

Service health is not enough to validate configuration ownership or UI behavior. The checks below expose failures while the services remain healthy.

### 1. Runtime settings can rewrite Git

`~/.config/dms/settings.json` resolves to:

```text
~/.dotfiles/hosts/framework/config/dms/settings.json
```

It is writable. This is configured by the uncommitted `mkOutOfStoreSymlink` change in `hosts/framework/home.nix`.

Comparing parsed JSON against HEAD found **193 changed top-level settings**, including schema and migrated/default-looking fields. This is not a suitable way to distinguish intentional preferences from application rewrites. Do not commit the raw diff wholesale.

`plugin_settings.json` is currently a writable regular file, although the proposed Home Manager configuration declares an out-of-store link. That mismatch is observed; the writer responsible for replacing that particular link has not been established.

Quickshell's `FileView` supports atomic replacement writes; a symlink is not a general ownership boundary.[2] DMS's Niri generator explicitly resolves its target with `readlink -f`, so linking generated output into the checkout or store is especially inappropriate.[3]

### 2. Active Niri configuration ignores several live DMS outputs

`modules/home/gui/niri/config.kdl` includes frozen files under:

```text
niri/dms/defaults/{layout,alttab,colors,outputs,wpblur,cursor}.kdl
```

DMS generates the corresponding files directly under `~/.config/niri/dms/`.[3] On this host, the generated layout, colors, cursor, Alt-Tab, and wallpaper-blur files differ from the included defaults. This explains how DMS can successfully change its files without changing the effective Niri configuration.

All nine existing top-level DMS KDL files individually pass validation with the running Niri binary. This is not currently explained by invalid syntax in those files. Combined include precedence and startup from missing generated files still need explicit validation.

### 3. Nix and DMS both claim generated output paths

Home Manager deploys immutable files at `niri/dms/binds.kdl` and `niri/dms/windowrules.kdl`. DMS also considers these its integration output paths.[3][4]

The journal contains this concrete failure:

```text
failed to update DMS window rule dms-floating-windows
open .../.config/niri/dms/windowrules.kdl: read-only file system
```

The fix is not to make the Nix store writable, add more `force = true`, or point these paths at Git. Move hand-authored configuration out of the DMS-owned namespace.

### 4. Theme ownership is overlapping

Home Manager/Stylix owns GTK CSS, Qt configuration, Ghostty, and Kitty configuration. Those deployed files currently resolve into the read-only store.

DMS settings enable its own and user Matugen templates, with targets including GTK, Qt, Ghostty, Kitty, Neovim, and several other applications. Enabled templates establish overlapping ownership; this audit did not trigger a theme change or prove that every target is currently being rewritten.

For the first migration, let Stylix/Nix own external application themes and disable DMS generation for those same destinations. The pinned shell supports `DMS_DISABLE_MATUGEN`; its current documentation describes it as a static-theme/troubleshooting option.[5] Keep DMS's own appearance explicit rather than enabling two independent writers for application configuration.

### 5. Portal intent is split between layers

The evaluated system Niri portal configuration selects GTK for file choosing. The Home Manager XDG module declares a common `termfilechooser` preference. The observed active desktop-specific file is `/etc/xdg/xdg-desktop-portal/niri-portals.conf`, and it selects GTK; there is no active user portal configuration directory in this session.

Choose and declare the desired file chooser in the effective **Niri-specific** portal configuration. Do not assume a common preference overrides it. Preserve GNOME's screencast implementation and GTK fallback; these are upstream Niri recommendations and are already provided by the NixOS Niri module.[6][7]

No portal service restart or screen-sharing experiment was performed. File picking, screencast selection, and application activation need functional checks, not just a reachable Settings portal.

### 6. There are separate plugin errors

The DMS journal reports `Invalid write to global property "recording"` from the Audio and GIF status callbacks. The corresponding QML callbacks assign to unqualified `recording`; surrounding handlers commonly use `root.recording`.

Treat these as a separate plugin regression with an isolated Quickshell check. Do not expect an ownership migration to fix plugin callback behavior automatically.

### 7. Some inputs are unnecessarily host-local

- `dejli-desktop` executes a binary from a developer checkout under `~/projects/`, rather than an installed package.
- The former `hosts/framework/config/dms/session.json` snapshot contained launcher history, last-player identity, and an absolute checkout wallpaper path. It was not a portable desktop profile.
- Niri helper scripts reference `pkgs.niri`, while the compositor runs `pkgs.niri-release-keybinds`.
- The custom compositor package reports `25.11-release-keybinds`; pinned nixpkgs supplies Niri `26.04`.

Do not automatically replace the custom compositor: the GitHub comparison between its pinned commit and `v26.04` is **diverged**, with four commits unique to the custom side. Feature parity for release bindings must be checked rather than inferred from version numbers.[8]

## A reproducible failing ownership check

Run from the repository root. This is read-only and currently fails all three ownership assertions:

```sh
python3 - <<'PY'
from pathlib import Path
import os

repo = Path.cwd()
checks = {
    "DMS settings cannot write into Git": not (
        Path.home() / ".config/dms/settings.json"
    ).resolve().is_relative_to(repo),
    "DMS window-rule output is writable": os.access(
        Path.home() / ".config/niri/dms/windowrules.kdl", os.W_OK
    ),
    "DMS keybind output is not store-owned": not (
        Path.home() / ".config/niri/dms/binds.kdl"
    ).resolve().is_relative_to("/nix/store"),
}
for name, passed in checks.items():
    print(("PASS " if passed else "FAIL ") + name)
assert all(checks.values()), "Desktop configuration ownership is inconsistent"
PY
```

These checks are necessary, not sufficient: generated files must also be included deliberately and given the right precedence.

## What other setups do better

### Omarchy: separate shipped defaults, personal overrides, and generated state

Research used the current `quattro` branch at `f766bfa510711e4c3f84a38190e65c65449d9338`, not older Hyprland `.conf` recipes.

Its user entrypoint loads shipped defaults first and personal monitor/input/binding/appearance/autostart modules afterward. Generated theme modules are loaded from `~/.local/state`; theme switching stages a next-theme directory before publishing the current theme. Its refresh command explicitly backs up and replaces a user config instead of pretending that a copied default remains declaratively managed.[9]

**Borrow:** clear ownership, a generated-state namespace, deliberate include order, and explicit promotion/reset operations.

**Do not borrow blindly:** UWSM/Hyprland startup wiring or imperative installation/theme mutations. Omarchy is a useful desktop-integration reference, not a stronger substitute for this repository's Nix lock and store-based configuration. Niri already supplies its own systemd session integration.[6]

### Upstream DMS/Dux: current Nix support is better than old default-copy recipes

The pinned DMS input is `9b413296b16721f7679fb62e624cb1ed2433fa58`, running as `2.0.0+date=2026-10-20_9b41329` with Quickshell `0.3.2`. Source and current documentation now use Dux terminology while retaining compatibility option names.[5][10]

The pinned Home Manager module supports:

- `programs.dank-material-shell.settings`;
- declarative plugin installation and plugin settings;
- clipboard configuration;
- separate session configuration under `~/.local/state/dms/`.[10]

Its QML also supports `settings.json` plus sorted `config.d/*.json` files, merges top-level keys, and routes saves back to the file owning each key. Read-only save failures are tracked. This is **not** a generic recursive merge with an automatically separate writable GUI override layer.[11]

Use the pinned source as authority. Older `default-settings.json` copy-once recipes do not describe these current options. Never enable both systemd startup and compositor `spawn-at-startup` for the shell.[5]

### Native NixOS/Home Manager Niri modules: fewer custom integration layers

The pinned NixOS module already provides session registration, appropriate systemd integration, portal defaults, and protection against restarting the compositor during an ordinary rebuild. The pinned Home Manager module can generate and build-time validate KDL with an explicitly selected package.[7][12]

**Borrow:** build-time validation with the same compositor package used at runtime; let the official Niri session own environment import and session lifecycle.

A second session manager is not needed just because another distro uses one. Avoid gratuitous portal restart scripts and global toolkit overrides. In particular, upstream warns against setting `GDK_BACKEND` globally because it breaks screencasting.[6]

### Noctalia: a clearer reference for config versus GUI state

Research used `ec13cd01a9c2e2ef215da9d90e6933e1b113b9a6`, not older Quickshell-era configuration instructions.

Its documented model separates curated config from GUI overrides in `~/.local/state/noctalia/settings.toml`, never rewrites curated config during migration, and provides config export and validation. Its Home Manager module validates generated configuration at build time.[13]

This is architecturally attractive, but **GUI overrides still win**. Merely switching shells would not guarantee that a used home directory matches its declared baseline. A switch would also require replacing or porting the current DMS plugins. Keep it as an alternative if DMS's configuration behavior remains too awkward after ownership is corrected.

## Proposed ownership model

| Component | Owner | Storage / rule |
|---|---|---|
| Niri package, login session, greeter, PAM, portal packages | NixOS | Pinned packages and system modules |
| DMS startup | Exactly one systemd unit | Keep the current NixOS-owned unit initially; do not also enable Home Manager startup |
| DMS preferences and plugin declarations | Home Manager / Git | Store-backed settings, no links back into the checkout |
| Hand-authored Niri bindings, window rules, host outputs | Home Manager / Git | `niri/managed/` or another namespace DMS never writes |
| DMS integration outputs | DMS | Writable `niri/dms/`, never store-owned or linked into Git |
| External app theming | Stylix / Nix | Disable overlapping DMS/Matugen targets |
| Histories, discovery, transient UI/session state | Applications | State/cache directories outside Git |
| Developer-specific Dejli binary | Installed package or explicit development override | No implicit dependency on a checkout build |

A user service could move to Home Manager later. That is not necessary to solve ownership now; if moved, disable the NixOS service in the same change.

### Niri includes

Keep an immutable main config and immutable managed preferences. Include only the DMS-generated integration files intentionally delegated to DMS. Put authoritative managed overrides after generated fragments where Niri's merge semantics allow it; do not assume all nodes, especially bindings and window rules, merge identically.

The currently installed compositor was directly tested with a missing `include optional=true "missing.kdl"` and accepts it. Optional includes therefore allow a clean first login before generated files exist. This does not prove generated values are deterministic or that duplicate bindings are acceptable.

Do not preserve the existing frozen defaults as a second, competing desktop configuration. Before removing them, promote any desired values into the managed baseline and validate the combined config.

## Migration order

1. **Preserve current intent.** Back up live settings/state privately. Review the existing uncommitted changes; extract intended preferences instead of accepting all migration churn. Preserve existing custom bindings and recording workflows.
2. **End writes into Git.** Add a dedicated Home Manager DMS module using the pinned upstream settings/plugin facilities. Replace the out-of-store settings links. Leave histories and session state mutable; do not make the entire session JSON immutable just to pin one preference.
3. **Resolve generated-file ownership.** Move hand-authored bindings/window rules out of `niri/dms/`; use deliberate optional generated includes and final managed overrides. Safely migrate existing files rather than deleting them during a running session.
4. **Choose one theme and portal owner.** Disable overlapping application theme writers. Declare the effective Niri file chooser once. Reassess custom portal drop-ins only after checking actual session ordering; do not remove working lifecycle safeguards blindly.
5. **Repair plugins independently.** Reproduce recording-status callback behavior in isolation, fix qualification and dependencies, and replace checkout-only executable assumptions where feasible.
6. **Evaluate a compositor upgrade separately.** Compare release-binding behavior and DMS features against the standard pinned Niri package. Do not change versions, ownership, themes, and session managers in one opaque step.
7. **Activate with a recovery route.** Keep the previous generation, a TTY login, and a known-good terminal binding available. Do not restart the live compositor as part of configuration cleanup.

## Acceptance criteria

- A clean home with no generated DMS files can start the declared session.
- Rebuilding and using normal desktop controls do not modify the Git checkout.
- Managed preferences have the documented precedence; GUI persistence follows the chosen policy.
- The combined Niri configuration is validated during the build with the runtime compositor package.
- No DMS-generated destination points into Git or the store.
- Exactly one compositor session and one DMS instance own the desktop services.
- Login/logout, suspend/resume, monitor hotplug, file chooser, screencast selection, lock screen, clipboard, and recording-status workflows pass functional checks.
- The journal has no read-only generated-file errors or recording callback errors; known optional-feature warnings are distinguished from failures.
- Rollback restores declared desktop preferences without requiring a developer checkout or hidden hand-edited config.

## Preference policy selected

The user selected **declarative-first**. The implementation above materializes writable runtime preferences from the immutable baseline at startup; it does not rely on saving GUI edits back through source symlinks. The original alternatives were:

- **Declarative-first (recommended):** reviewed preferences are authoritative; GUI experiments are temporary unless explicitly exported/reviewed into Git. Operational state such as volume and history may still persist.
- **Persistent GUI overrides:** the baseline is reproducible, but the effective desktop also depends on local overrides. Provide explicit inspect/export/reset commands and do not call the resulting live state fully declarative.

This choice affects settings handling, runtime-state boundaries, and what a rollback promises. It should not be hidden inside symlink or activation tricks.

## Sources

1. [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/).
2. [Quickshell 0.3.2 FileView: atomicWrites](https://quickshell.org/docs/v0.3.2/types/Quickshell.Io/FileView/).
3. [Pinned DMS NiriService.qml](https://github.com/AvengeMedia/DankMaterialShell/blob/9b413296b16721f7679fb62e624cb1ed2433fa58/quickshell/Services/NiriService.qml): generation destinations and `targetFileCommand` / `replaceFileCommand`.
4. [Pinned DMS CompositorService.qml](https://github.com/AvengeMedia/DankMaterialShell/blob/9b413296b16721f7679fb62e624cb1ed2433fa58/quickshell/Services/CompositorService.qml): automatic floating/opaque window-rule maintenance.
5. [Dux NixOS flake installation](https://duxlabs.dev/docs/dms/nixos-flake) and [advanced configuration](https://duxlabs.dev/docs/dms/advanced-configuration). Current documentation can describe features newer than the pinned input.
6. Niri upstream: [integration](https://niri-wm.github.io/niri/Integrating-niri.html), [systemd setup](https://niri-wm.github.io/niri/Example-systemd-Setup.html), and [important software / portals](https://niri-wm.github.io/niri/Important-Software.html).
7. [Pinned nixpkgs Niri module](https://github.com/NixOS/nixpkgs/blob/5adc50831c259f87faeb09ddf930d43597197473/nixos/modules/programs/wayland/niri.nix).
8. [Custom Niri commit](https://github.com/YaLTeR/niri/commit/a5591c69fa81b69d6315f07609acde97eae31c93) and [comparison with v26.04](https://github.com/YaLTeR/niri/compare/a5591c69fa81b69d6315f07609acde97eae31c93...v26.04).
9. Omarchy at `f766bfa510711e4c3f84a38190e65c65449d9338`: [user entrypoint](https://github.com/basecamp/omarchy/blob/f766bfa510711e4c3f84a38190e65c65449d9338/config/hypr/hyprland.lua), [bootstrap](https://github.com/basecamp/omarchy/blob/f766bfa510711e4c3f84a38190e65c65449d9338/default/hypr/bootstrap.lua), [theme switching](https://github.com/basecamp/omarchy/blob/f766bfa510711e4c3f84a38190e65c65449d9338/bin/omarchy-theme-set), [theme templates](https://github.com/basecamp/omarchy/blob/f766bfa510711e4c3f84a38190e65c65449d9338/bin/omarchy-theme-set-templates), and [explicit refresh](https://github.com/basecamp/omarchy/blob/f766bfa510711e4c3f84a38190e65c65449d9338/bin/omarchy-refresh-config).
10. Pinned DMS Nix modules: [Home Manager](https://github.com/AvengeMedia/DankMaterialShell/blob/9b413296b16721f7679fb62e624cb1ed2433fa58/distro/nix/home.nix), [shared options](https://github.com/AvengeMedia/DankMaterialShell/blob/9b413296b16721f7679fb62e624cb1ed2433fa58/distro/nix/options.nix), and [NixOS](https://github.com/AvengeMedia/DankMaterialShell/blob/9b413296b16721f7679fb62e624cb1ed2433fa58/distro/nix/nixos.nix).
11. Pinned DMS [SettingsData.qml](https://github.com/AvengeMedia/DankMaterialShell/blob/9b413296b16721f7679fb62e624cb1ed2433fa58/quickshell/Common/SettingsData.qml) and [SessionData.qml](https://github.com/AvengeMedia/DankMaterialShell/blob/9b413296b16721f7679fb62e624cb1ed2433fa58/quickshell/Common/SessionData.qml).
12. [Pinned Home Manager Niri module](https://github.com/nix-community/home-manager/blob/ab97a5d09e0f2aa7339cfd35ec5824fd6653e27c/modules/services/window-managers/niri.nix).
13. Noctalia at `ec13cd01a9c2e2ef215da9d90e6933e1b113b9a6`: [configuration ownership and precedence](https://github.com/noctalia-dev/noctalia-shell/blob/ec13cd01a9c2e2ef215da9d90e6933e1b113b9a6/docs/user/configuration/index.mdx) and [Home Manager module](https://github.com/noctalia-dev/noctalia-shell/blob/ec13cd01a9c2e2ef215da9d90e6933e1b113b9a6/nix/home-module.nix).
