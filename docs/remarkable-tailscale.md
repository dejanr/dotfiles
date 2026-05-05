# reMarkable Tailscale

This repo uses a bootstrap script instead of Nix for reMarkable Tailscale setup.

Why:
- reMarkable is not managed by this Nix repo
- Tailscale on reMarkable depends on device-native package tooling
- the device runs Tailscale in userspace networking mode

Reference guide:
- https://remarkable.guide/tech/tailscale.html

## Prerequisites

- SSH access to the reMarkable
- if needed, enable Wi-Fi SSH on the device:
  ```bash
  rm-ssh-over-wlan on
  ```

## Bootstrap

From this repo:

```bash
chmod +x scripts/remarkable-tailscale-bootstrap.sh
./scripts/remarkable-tailscale-bootstrap.sh 10.11.99.1 --login
```

This bootstraps, if needed:
- `vellum`
- `entware`
- `entware-rc`

The Vellum bootstrap is downloaded and checksum-verified on your local machine, then copied to the tablet. This avoids TLS issues some reMarkable devices have talking to GitHub directly.

Then installs:
- `tailscale` via Vellum
- `openssh-client` via Entware

On reMarkable OS upgrades, rerun the same script. It automatically runs `vellum upgrade` and, if needed, `vellum reenable` to restore Vellum-managed services like `tailscaled.service`.

The script also rewrites the Entware package URL to plain HTTP if needed, because some reMarkable devices fail TLS handshakes against the Entware mirror.

Then it runs:

```bash
/home/root/.vellum/bin/tailscale --socket=/run/tailscale/tailscaled.sock up --ssh --qr
```

Approve the login from the printed URL or QR code.

If upstream rotates the Vellum bootstrap checksum, the script will stop and you should update it from:
- https://github.com/vellum-dev/vellum-cli

## What this gives you

- inbound Tailscale access to the tablet
- Tailscale SSH support
- outbound SSH from the tablet to tailnet devices via:
  ```sshconfig
  Host myalias
    User myuser
    HostName my.host.name
    Port 22
    ProxyCommand /home/root/.vellum/bin/tailscale --socket=/run/tailscale/tailscaled.sock nc %h %p
  ```

## Notes

- reMarkable does not provide `/dev/net/tun`, so this is userspace networking
- inbound access works well
- outbound tailnet access needs proxy-aware tools
- this is best used for remote SSH/admin access to the tablet
