#!/usr/bin/env bash

set -euo pipefail

host="${1:-10.11.99.1}"
login="${2:-}"
ssh_target="root@${host}"
vellum_bootstrap_url="https://github.com/vellum-dev/vellum-cli/releases/latest/download/bootstrap.sh"
vellum_bootstrap_checksum="3958563255dd98d34a45d11e7884cd53d9f5afdd1f19ce3cbbbf6ee409d3c894"
vellum_key_url="https://raw.githubusercontent.com/vellum-dev/vellum/main/keys/packages.rsa.pub"
vellum_apk_aarch64_url="https://github.com/vellum-dev/apk-tools/releases/download/v3.0.3/apk-aarch64"
vellum_apk_armv7_url="https://github.com/vellum-dev/apk-tools/releases/download/v3.0.3/apk-armv7"
vellum_cli_arm64_url="https://github.com/vellum-dev/vellum-cli/releases/latest/download/vellum-linux-arm64"
vellum_cli_armv7_url="https://github.com/vellum-dev/vellum-cli/releases/latest/download/vellum-linux-armv7"
local_tmpdir="$(mktemp -d)"
local_bootstrap="$local_tmpdir/vellum-bootstrap.sh"
local_offline_dir="$local_tmpdir/vellum-offline"
ssh_opts=(
  -o StrictHostKeyChecking=accept-new
  -o ConnectTimeout=10
)

cleanup() {
  rm -rf "$local_tmpdir"
}
trap cleanup EXIT

ssh_remote() {
  ssh "${ssh_opts[@]}" "$ssh_target" "$@"
}

wait_for_ssh() {
  local attempts="${1:-45}"
  local delay="${2:-2}"
  local attempt

  for ((attempt = 1; attempt <= attempts; attempt++)); do
    if ssh_remote 'true' >/dev/null 2>&1; then
      return 0
    fi
    sleep "$delay"
  done

  return 1
}

reenable_vellum_packages() {
  ssh_remote '
set -euo pipefail
if [ ! -x /home/root/.vellum/bin/vellum ]; then
  exit 0
fi
rm -f /tmp/vellum-reenable.log /tmp/vellum-reenable.exit
nohup sh -lc '"'"'
  export PATH="/home/root/.vellum/bin:$PATH"
  /home/root/.vellum/bin/vellum reenable > /tmp/vellum-reenable.log 2>&1
  rc=$?
  printf "%s\n" "$rc" > /tmp/vellum-reenable.exit
'"'"' >/dev/null 2>&1 </dev/null &
' >/dev/null

  wait_for_ssh

  local attempt
  for ((attempt = 1; attempt <= 45; attempt++)); do
    if ssh_remote 'test -f /tmp/vellum-reenable.exit' >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done

  ssh_remote '
set -euo pipefail
test -f /tmp/vellum-reenable.exit
cat /tmp/vellum-reenable.log
rc="$(cat /tmp/vellum-reenable.exit)"
rm -f /tmp/vellum-reenable.log /tmp/vellum-reenable.exit
exit "$rc"
'
}

ensure_tailscale_service() {
  local unit

  unit="$(ssh_remote 'systemctl list-unit-files --type=service --no-legend | grep -E "^(tailscaled|tailscale)\\.service" | head -n1 | awk '"'"'{print $1}'"'"'' || true)"

  if [ -z "$unit" ]; then
    echo "Restoring Vellum-managed services after OS upgrade..."
    reenable_vellum_packages
    unit="$(ssh_remote 'systemctl list-unit-files --type=service --no-legend | grep -E "^(tailscaled|tailscale)\\.service" | head -n1 | awk '"'"'{print $1}'"'"'' || true)"
  fi

  if [ -z "$unit" ]; then
    echo "Could not find a Tailscale systemd unit after package installation." >&2
    exit 1
  fi

  ssh_remote "set -euo pipefail; systemctl daemon-reload; systemctl enable --now \"$unit\"; systemctl --no-pager --full status \"$unit\" || true; /home/root/.vellum/bin/tailscale version || true"
}

remote_arch="$(ssh_remote 'uname -m')"
mkdir -p "$local_offline_dir"

curl -fsSL "$vellum_bootstrap_url" -o "$local_bootstrap"
echo "$vellum_bootstrap_checksum  $local_bootstrap" | sha256sum -c >/dev/null
curl -fsSL "$vellum_key_url" -o "$local_offline_dir/packages.rsa.pub"

case "$remote_arch" in
  aarch64)
    curl -fsSL "$vellum_apk_aarch64_url" -o "$local_offline_dir/apk-aarch64"
    curl -fsSL "$vellum_cli_arm64_url" -o "$local_offline_dir/vellum-linux-arm64"
    ;;
  armv7l)
    curl -fsSL "$vellum_apk_armv7_url" -o "$local_offline_dir/apk-armv7"
    curl -fsSL "$vellum_cli_armv7_url" -o "$local_offline_dir/vellum-linux-armv7"
    ;;
  *)
    echo "Unsupported reMarkable architecture: $remote_arch" >&2
    exit 1
    ;;
esac

read -r -d '' remote_install <<EOF || true
set -euo pipefail

export PATH="/home/root/.vellum/bin:/opt/bin:/opt/sbin:\$PATH"
remote_bootstrap="/tmp/vellum-bootstrap.sh"
remote_offline_dir="/tmp/vellum-offline"

find_vellum() {
  if command -v vellum >/dev/null 2>&1; then
    command -v vellum
  elif [ -x /home/root/.vellum/bin/vellum ]; then
    echo /home/root/.vellum/bin/vellum
  else
    return 1
  fi
}

find_opkg() {
  if command -v opkg >/dev/null 2>&1; then
    command -v opkg
  elif [ -x /opt/bin/opkg ]; then
    echo /opt/bin/opkg
  else
    return 1
  fi
}

if ! vellum_bin="\$(find_vellum)"; then
  bash "\$remote_bootstrap" --offline "\$remote_offline_dir"
  export PATH="/home/root/.vellum/bin:\$PATH"
  vellum_bin="\$(find_vellum)"
fi

"\$vellum_bin" upgrade || "\$vellum_bin" upgrade

if ! opkg_bin="\$(find_opkg)"; then
  "\$vellum_bin" add entware entware-rc
  export PATH="/opt/bin:/opt/sbin:\$PATH"
  opkg_bin="\$(find_opkg)"
fi

"\$vellum_bin" add tailscale

if [ -f /opt/etc/opkg.conf ]; then
  sed -i 's#https://bin.entware.net#http://bin.entware.net#g' /opt/etc/opkg.conf
fi

"\$opkg_bin" update
"\$opkg_bin" install openssh-client
EOF

remote_login='set -euo pipefail
export PATH="/home/root/.vellum/bin:/opt/bin:/opt/sbin:$PATH"
exec tailscale --socket=/run/tailscale/tailscaled.sock up --ssh --qr'

cat "$local_bootstrap" | ssh_remote 'mkdir -p /tmp/vellum-offline && cat > /tmp/vellum-bootstrap.sh && chmod +x /tmp/vellum-bootstrap.sh'
scp "${ssh_opts[@]}" "$local_offline_dir"/* "$ssh_target:/tmp/vellum-offline/"
ssh_remote "$remote_install"
ensure_tailscale_service

if [ "$login" = "--login" ]; then
  ssh -t "${ssh_opts[@]}" "$ssh_target" "$remote_login"
else
  cat <<EOF
Installed Tailscale packages on ${ssh_target}.

Next step:
  ssh ${ssh_target} /home/root/.vellum/bin/tailscale --socket=/run/tailscale/tailscaled.sock up --ssh --qr

Or rerun with:
  $0 ${host} --login
EOF
fi
