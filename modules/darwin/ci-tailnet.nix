{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.darwin.ci-tailnet;
  tailscale = pkgs.tailscale;
  stateDir = "/var/db/macos-ci-tailscale";
  socket = "${stateDir}/tailscaled.sock";
  sshdConfig = "/etc/ssh/macos-ci-sshd.conf";
  authorizedKeys = "/etc/ssh/macos-ci-authorized-keys";
  cli = pkgs.writeShellApplication {
    name = "macos-ci-tailscale";
    text = ''
      exec ${lib.getExe' tailscale "tailscale"} --socket=${socket} "$@"
    '';
  };
in
{
  options.modules.darwin.ci-tailnet = {
    enable = lib.mkEnableOption "key-only OpenSSH through an isolated userspace Tailscale node";
    authorizedKeysFile = lib.mkOption {
      type = lib.types.path;
      description = "Public SSH keys allowed to log into the guest administrator account.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh.enable = false;
    environment.systemPackages = [ cli ];

    environment.etc = {
      "ssh/macos-ci-sshd.conf".text = ''
        ListenAddress 127.0.0.1:2222
        HostKey /etc/ssh/ssh_host_ed25519_key
        AuthorizedKeysFile ${authorizedKeys}
        AllowUsers ${config.system.primaryUser}
        AuthenticationMethods publickey
        PermitRootLogin no
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        UsePAM yes
        DisableForwarding yes
        Subsystem sftp /usr/libexec/sftp-server
      '';
    };

    system.activationScripts.extraActivation.text = ''
      (
        /usr/bin/install -d -o root -g wheel -m 0700 ${stateDir} || exit 1
        # StrictModes checks the resolved path; /nix/store is group-writable.
        keys=$(/usr/bin/mktemp /etc/ssh/.macos-ci-keys.XXXXXXXX) || exit 1
        trap '/bin/rm -f "$keys"' EXIT
        /usr/bin/install -o root -g wheel -m 0644 ${cfg.authorizedKeysFile} "$keys" || exit 1
        /bin/mv -f "$keys" ${authorizedKeys} || exit 1
      ) || exit 1
    '';

    launchd.daemons = {
      macos-ci-tailscaled = {
        command = lib.escapeShellArgs [
          (lib.getExe' tailscale "tailscaled")
          "--tun=userspace-networking"
          "--state=${stateDir}/tailscaled.state"
          "--socket=${socket}"
        ];
        serviceConfig = {
          RunAtLoad = true;
          KeepAlive = true;
        };
      };
      macos-ci-sshd = {
        command = "/usr/sbin/sshd -D -e -f ${sshdConfig}";
        serviceConfig = {
          RunAtLoad = true;
          KeepAlive.SuccessfulExit = false;
        };
      };
    };
  };
}
