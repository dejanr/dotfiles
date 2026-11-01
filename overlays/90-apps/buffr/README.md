# Buffr on Framework

The package builds Buffr 0.14.17 from pinned source and CEF 152.0.6, matching
`cef-dll-sys` in its lockfile. CEF and Cargo dependencies are fetched separately
with fixed hashes; the build runs offline. The Linux patch disables decorations
and forwards the existing Wayland app ID for desktop integration.

Framework enables `modules.home.gui.browser.buffr`, which installs `buffr`
(Personal) and `buffr-work` (Work). Their data and caches are isolated under
`~/.local/share/buffr-profiles/` and `~/.cache/buffr-profiles/`; both use the
Home Manager settings at `~/.config/buffr/config.toml`. Niri's Mod+W/Mod+E
shortcuts select those profiles. External links use Personal. The launchers set
`BUFFR_PROFILE_LABEL` to show Personal/Work at the top-right of the tab strip
and in the window title; unlabeled launches retain the upstream appearance.

Qutebrowser data is not imported or deleted. Buffr starts with fresh profiles,
so websites require a new login. Other hosts retain Qutebrowser.

```sh
nix build .#buffr
nix build --no-link .#checks.x86_64-linux.framework-desktop
sudo nixos-rebuild switch --flake .#framework
```

When updating, pin the source revision/hash and Cargo hash together. Match the
CEF archive version to the Rust binding version and update its hashes and
`archive.json` metadata. Keep Nix's Vulkan loader rather than CEF's bundled
loader, which does not discover NixOS graphics drivers correctly.
