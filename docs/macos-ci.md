# macOS CI runner

`mbp-work-ci` is an Apple Silicon VM on `mbp-work` with its own nix-darwin profile. It starts with one repository registration for `dejli/draw`. The runner has only the `isolated-macos` label; Linux jobs still use `isolated-ci` on Framework and Omega.

## Host: `M-G1997RD02K`

From the dotfiles root on the physical Mac:

```bash
sudo darwin-rebuild switch --flake "path:$PWD#M-G1997RD02K"
macos-ci-vm provision
macos-ci-vm run
```

Wait for any in-progress Tart restore to finish before running `provision`. On a fresh host, `provision` downloads and verifies the pinned Apple restore image (macOS 26.6.2, build `25G83`), then creates the VM. The download is about 20 GB and is not a dependency of the Nix system build. If the VM already exists, `provision` updates its CPU and RAM without recreating its disk; stop the VM first. The `mbp-work` profile uses 8 vCPUs, 16 GiB of RAM, and a sparse 256 GB disk for new guests. The disk setting does not grow an existing VM. For an existing macOS guest, increasing the virtual disk size alone does not extend the main APFS container if the recovery partition is in the way. Back up or clone the stopped VM before [resizing its partitions](https://tart.run/faq/#disk-resizing).

Host activation installs the pinned Softnet helper setuid-root, executable only by the host's admins. It does not add a sudo rule. The launcher refuses to fall back to plain NAT. It blocks the bridge gateway and Tailscale's shared IPv4 range in addition to Softnet's default private-network filtering. No host files, clipboard, audio, credentials, or incoming port forwards are passed to the guest. Always boot the CI guest through `macos-ci-vm`, not `tart run` directly.

If the host user's primary group has no resolvable name, the launcher uses `newgrp admin` for the VM process only. This requires an existing membership in the Mac's `admin` group and does not change the account.

## Guest: `mbp-work-ci`

1. Finish Setup Assistant with a local admin named `dejanr` (or change `system.primaryUser` in the guest profile). Skip the Apple Account and do not import anything from the host. Leave Remote Login and Screen Sharing off. Nix creates the separate `_dotfilesci` service account; do not create it in Setup Assistant.
2. As the guest admin, install Apple's Command Line Tools (`xcode-select --install`) and [Determinate Nix](https://docs.determinate.systems/determinate-nix/). The guest profile leaves the Determinate daemon in place. Draw's archive script uses Apple's `codesign` and `lipo`, but the build does not need full Xcode. If DNS initially fails, list the guest network services with `networksetup -listallnetworkservices` and run `sudo networksetup -setdnsservers Ethernet 9.9.9.9 149.112.112.112` (use the actual interface's service name). The guest profile configures DNS on `Ethernet` going forward.
3. Check out a dotfiles revision that contains this guest configuration inside the guest. Do not forward SSH credentials or mount host files. From the guest checkout, build and activate it:

   ```bash
   system=$(nix --extra-experimental-features 'nix-command flakes' build --no-link \
     --print-out-paths "path:$PWD#darwinConfigurations.mbp-work-ci.system")
   sudo "$system/sw/bin/darwin-rebuild" switch --flake "path:$PWD#mbp-work-ci"
   ```

4. Include `/etc/nix/dotfiles-ci.conf` at the end of `/etc/nix/nix.custom.conf` with `!include /etc/nix/dotfiles-ci.conf`, then reload Determinate Nix with `sudo launchctl kickstart -k system/systems.determinate.nix-daemon`.
5. Verify `uname -m` reports `arm64`, `xcode-select -p` works, `sudo -u _dotfilesci /run/current-system/sw/bin/nix store ping` works, and `curl -fsSL https://api.github.com/zen` works from the guest. Verify the guest cannot connect to a known listening TCP service on the host's VM gateway or reach a known private LAN/Tailscale endpoint. Do not mount the host's Nix store or configure the tailnet caches in this guest.

## SSH over Tailscale

The guest uses OpenSSH with the public keys pinned by the `ssh-keys` flake input (`https://github.com/dejanr.keys`). Only the guest administrator can log in. Update the `ssh-keys` input and rebuild to add or revoke keys. Apple's Remote Login stays off; the dedicated SSH server listens only on guest loopback. No private keys are copied to the guest.

Before joining the guest to the tailnet, use [Access controls](https://login.tailscale.com/admin/acls) to define `tag:macos-ci` and grant only your Tailscale identity (or selected admin devices) access to `tag:macos-ci` on `tcp:22`. Give the tag no outbound access to other tailnet devices or routed LANs. Check existing grants and ACLs for broader rules that match the tag: allows are additive. Add policy tests for the permitted admin, a denied source, and denied connections from the tag to your host and private services.

After activating the guest profile, use its local Terminal to join the tailnet and set up the TCP forwarder:

```bash
sudo macos-ci-tailscale up --hostname=mbp-work-ci --advertise-tags=tag:macos-ci --accept-dns=false --accept-routes=false
sudo macos-ci-tailscale serve --bg --tcp=22 tcp://127.0.0.1:2222
```

Follow the sign-in link from `up` and confirm the machine has the tag before running `serve`. Use **Serve**, not Funnel, and do not enable Tailscale SSH: OpenSSH validates the GitHub keys. Connect from an authorized device using `ssh dejanr@mbp-work-ci` (or its full MagicDNS name). Confirm TCP 22 is not reachable over the VM's non-Tailscale address, and leave Softnet enabled.

## Enroll for Draw

Use a repository registration only if everyone who can introduce or trigger jobs is trusted. A runner label is routing, not an access control; any eligible workflow in the repo can target it. Don't enroll public repositories or run untrusted PRs on it. To share one registration with additional private projects, set the guest's runner URL to the GitHub organization and set `modules.darwin.ci-runner.runnerGroup` to a group restricted to those repositories and, where supported, approved workflows on protected refs. Re-enroll after changing the registration scope. The persistent guest does not reset between builds.

In [Draw’s runner settings](https://github.com/dejli/draw/settings/actions/runners), choose **New self-hosted runner → macOS → ARM64** and copy only the short-lived registration token. The runner binary is already installed by the guest flake. Inside the guest, enroll it and start the daemon:

```bash
sudo -H -u _dotfilesci /run/current-system/sw/bin/macos-ci-runner enroll
sudo launchctl kickstart system/org.nixos.macos-ci-runner
```

Enter the token at the prompt; do not put it in a command, the Nix store, or Git. Registration state stays in `/Users/_dotfilesci/.github-runner`. The launchd service runs without a GUI login and will pick up that registration after reboot. Don't store release signing keys or other long-lived secrets in the VM. Update the guest's locked nixpkgs regularly: the runner version is Nix-managed and GitHub eventually stops routing to outdated runners.

Verify `mbp-work-ci` is **Online / Idle** in GitHub before changing Draw's workflow. Edit the source (`nix/github/workflows/ci.nix`) to route the manual macOS job to `isolated-macos`, remove the Nix installer action, and keep it off PR events. Regenerate with `nix run .#render-workflows`. Dispatch from a trusted ref and verify the `Draw-macos-arm64` artifact. Leave the Linux job unchanged.

The host profile starts the VM headless at login and launchd restarts it after a stop. See `~/Library/Logs/macos-ci-vm.log`. For maintenance, unload the LaunchAgent before `tart stop mbp-work-ci`; otherwise launchd starts the VM again. After maintenance, bootstrap the agent again. Run both commands as the host login user:

```bash
launchctl bootout "gui/$(id -u)/org.nixos.macos-ci-vm"
# After maintenance:
launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/org.nixos.macos-ci-vm.plist
```

The guest profile disables idle system sleep. The host launcher holds a sleep assertion on AC power while Tart runs; keep the Mac plugged in and awake. A closed lid or host shutdown can still make the runner unavailable. To decommission it, remove the GitHub registration, turn off host autostart, shut down the guest, disable the host module and switch, then remove `/Library/PrivilegedHelperTools/dotfiles-ci/softnet` if it is no longer needed.
