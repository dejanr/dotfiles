# CI bootstrap

The [Framework](../hosts/framework/configuration.nix) and [Omega](../hosts/omega/configuration.nix) configs define Attic and the isolated runner VMs. These are the one-time steps outside Nix. For native Apple Silicon app builds, see [the macOS runner](macos-ci.md). Use self-hosted runners only for trusted workflows on protected refs.

## Cache

Before enabling anonymous pulls, allow only Framework, Omega, and `mbp-work` to reach Framework and Omega on TCP 8444 over Tailscale. Check both address families: require allow tests for the three approved devices and deny tests for an unapproved device. Specify TCP in the tests so UDP access on that port doesn't affect the result. Tailscale grants are additive: audit both grants and ACLs for broader rules that match those endpoints. If another device needs TCP 8444 for a different service, grant access to that destination explicitly rather than restoring a blanket rule.

Check `tailscale serve status` before adding the persistent tailnet-only route. Never enable Funnel for either cache:

```bash
sudo tailscale serve --bg --https=8444 http://127.0.0.1:8081
```

On each server, once the tailnet policy is in place, create the cache or allow anonymous pulls on the existing one. Attic calls this `--public`; it does not change Tailscale reachability or grant push access. The existing-cache update patches only visibility, leaving retention unchanged. Use `cache=framework priority=41` on Framework and `cache=omega priority=42` on Omega:

```bash
(
  set -euo pipefail
  umask 077
  cache=framework priority=41
  cd /
  sudo -v
  XDG_CONFIG_HOME=$(mktemp -d)
  export XDG_CONFIG_HOME
  trap 'rm -rf -- "$XDG_CONFIG_HOME"' EXIT
  mkdir "$XDG_CONFIG_HOME/attic"
  token_file="$XDG_CONFIG_HOME/attic/setup-token"
  sudo atticd-atticadm make-token --sub cache-setup --validity 15m \
    --create-cache "$cache" --configure-cache "$cache" --pull "$cache" > "$token_file"
  printf '[servers.local]\nendpoint = "https://%s.cat-vimba.ts.net:8444/"\ntoken-file = "%s"\n' \
    "$cache" "$token_file" > "$XDG_CONFIG_HOME/attic/config.toml"
  if attic cache info "local:$cache" >/dev/null 2>&1; then
    printf 'Authorization: Bearer %s\n' "$(tr -d '\r\n' < "$token_file")" > "$XDG_CONFIG_HOME/attic/auth-header"
    curl -qfsS --noproxy '*' --request PATCH \
      --header "Host: $cache.cat-vimba.ts.net:8444" \
      --header "@$XDG_CONFIG_HOME/attic/auth-header" \
      --header 'Content-Type: application/json' --data '{"is_public":true}' \
      "http://127.0.0.1:8081/_api/v1/cache-config/$cache"
  else
    attic cache create "local:$cache" --public --priority "$priority"
  fi
  attic cache info "local:$cache"
)
```

From an approved client, verify `curl -qfsS https://framework.cat-vimba.ts.net:8444/framework/nix-cache-info` works without credentials. Framework, Omega, mbp-work, and enrolled guests share the URLs and public signing keys in [`tailnet-caches.nix`](../modules/ci/tailnet-caches.nix). With external Nix on macOS, include `/etc/nix/dotfiles-ci.conf` and reload the daemon.

## Runner

Each guest can use all 32 logical CPUs without reserving or pinning any. Nix runs one local build at a time and tells the builder it can use all guest CPUs. Guest RAM is capped at 64 GiB on Framework and 32 GiB on Omega. Virtio free-page reporting returns unused guest pages to the host without lowering that cap. Heavy builds can still compete with desktop workloads for CPU and disk I/O.

New guests get a sparse 128 GiB disk. To grow an existing disk without replacing it, use `virsh blockresize` on the host, then grow partition 1 and its ext4 filesystem inside the guest. Changing the image size in Nix does not resize an existing disk.

If a VM is already defined, shut it down and re-run `virsh define` with the updated domain XML to apply CPU or RAM changes. Keep the existing disk.

Before enrolling, restrict runner access to the selected trusted workflow on a protected ref using a GitHub runner group where supported. Labels only select runners, and a protected Environment only gates publishing secrets; neither prevents another workflow from claiming a runner. If workflow restrictions aren’t available, enroll only in a private repo where everyone who can introduce or trigger runner jobs is trusted. Do not route untrusted pull-request code to these runners.

On the host, choose `framework-ci` or `omega-ci` as `guest`. Save a module at `~/.config/dotfiles-ci/<guest>.nix` with the admin SSH public key, private repo URL, and cache routes. Framework example (swap the two hostnames and CA filename for Omega):

```nix
{
  users.users.root.openssh.authorizedKeys.keys = [ "ssh-ed25519 REPLACE_WITH_PUBLIC_KEY" ];
  services.github-runners.nix-ci = {
    enable = true;
    url = "https://github.com/OWNER/PRIVATE-REPO";
  };
  networking.hosts."192.168.186.1" = [ "framework.cat-vimba.ts.net" ];
  networking.hosts."192.168.187.1" = [ "omega.cat-vimba.ts.net" ];
  security.pki.certificateFiles = [ ./framework-ci-attic-root.crt ];
}
```

Copy **only** the host's public bridge CA from `/var/lib/caddy/.local/share/caddy/pki/authorities/<guest>-attic/root.crt` beside the profile as `<guest>-attic-root.crt`. Check that `192.168.186.0/24` and `192.168.187.0/30` don't overlap existing routes, then provision from the dotfiles root:

```bash
(
  set -euo pipefail
  guest=framework-ci
  guest_config="(builtins.getFlake (toString ./.)).nixosConfigurations.$guest.extendModules {
    modules = [ (/. + (builtins.getEnv \"HOME\" + \"/.config/dotfiles-ci/$guest.nix\")) ];
  }"
  image=$(nix build --impure --no-link --print-out-paths --expr "($guest_config).config.system.build.ciImage")
  disk="/var/lib/libvirt/images/$guest.qcow2"
  sudo install -d /var/lib/libvirt/images
  sudo cp --sparse=always --update=none-fail "$image/$guest.qcow2" "$disk"
  sudo chmod 0600 "$disk"
  sudo systemctl restart libvirtd-config.service
  sudo systemctl restart libvirtd.service
  virsh=(sudo virsh -c qemu:///system)
  "${virsh[@]}" net-define "/etc/libvirt/$guest-network.xml"
  "${virsh[@]}" net-start "$guest"
  sudo "/etc/libvirt/$guest-nft" list table inet dotfiles_ci
  "${virsh[@]}" define "/etc/libvirt/$guest-domain.xml"
  "${virsh[@]}" start "$guest"
)
```

SSH into the guest as `root@192.168.186.2` with the admin key. From GitHub **Settings → Actions → Runners → New self-hosted runner**, copy the short-lived registration token. Store it with mode `0600` at `/var/lib/dotfiles-ci-registration/token` in the guest and restart `github-runner-nix-ci.service`. Leave the token file in place for subsequent restarts.

After provisioning, the host's `<guest>-start.service` starts the isolated network before starting its VM at boot. The hosts shut guests down cleanly instead of saving their memory state, so the runner boots with a fresh clock. No libvirt autostart flags are required. To check after a host reboot, run `journalctl -b -u <guest>-start.service` on that host and confirm the runner is **Online** in GitHub.

For two private repositories on GitHub Free, set `modules.ci.secondaryRunnerRepository = "OWNER/OTHER-REPO";` in each guest profile. Use a second repository registration token at `/var/lib/dotfiles-ci-registration/secondary-token` and start `github-runner-nix-ci-secondary.service`. Use separate tokens and keep both repos limited to trusted users. The second registration has its own service account and no default labels; set `services.github-runners.nix-ci.noDefaultLabels = true;` for the first as well to keep generic `self-hosted` jobs off these VMs. Use `runs-on: isolated-ci` to let either VM pick up a job. Both registrations on a VM share its Nix store, CPU, RAM, and disk. Keep `-modcacherw` in `GOFLAGS` if a runner overrides it, so GitHub checkout can remove Go module directories left by previous jobs.

For publishing, mint separate `--pull CACHE --push CACHE` tokens and store them in a protected GitHub Environment. Run `attic push framework:framework ./result` and `attic push omega:omega ./result` for the same build output, with both servers configured in the Attic client. Try both even if one is unavailable; missed uploads are not replicated automatically.

Validate the Nix configuration with `nix build --no-link .#checks.x86_64-linux.nix-ci`. Before using a guest for CI, verify it can pull from both cache relays but cannot reach host services or other tailnet devices directly.

For guest updates, build `config.system.build.toplevel` using the same profile, `nix copy --to ssh-ng://root@192.168.186.2` the closure, then set the guest's system profile and switch to it. Do not overwrite its disk.
