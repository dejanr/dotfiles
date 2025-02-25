{ pkgs, lib, config, ... }:

# System related secrets that are exported in /run/secrets/*

# Use this for more secret secrets, that should be only accessible by sudo

{
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.sshKeyPaths = [
    "/home/dejanr/.ssh/id_ed25519"
  ];
  sops.age.keyFile = "~/.config/sops/age/keys.txt";
  sops.secrets.openvpn_office_pass = { };
  sops.secrets.openvpn_office_conf = { };
}

