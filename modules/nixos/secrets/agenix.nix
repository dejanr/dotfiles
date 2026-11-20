{
  config,
  lib,
  ...
}:

let
  atticSecrets = {
    framework = ../../../secrets/attic_framework_server.age;
    omega = ../../../secrets/attic_omega_server.age;
  };
  atticSecret = atticSecrets.${config.networking.hostName} or null;
  managedAttic = config.modules.ci.attic.enable && atticSecret != null;
in
{
  # Prefer host SSH keys at boot; keep the user key as a fallback for hosts not yet rekeyed.
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_rsa_key"
    "/home/dejanr/.ssh/agenix"
  ];

  age.secrets.attic_server = lib.mkIf managedAttic {
    file = atticSecret;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  modules.ci.attic.environmentFile = lib.mkIf managedAttic (
    lib.mkDefault config.age.secrets.attic_server.path
  );

  systemd.services.atticd.restartTriggers = lib.mkIf managedAttic [ atticSecret ];
}
