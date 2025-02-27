{ pkgs, lib, config, ... }:

# System related secrets that are exported in /run/secrets/*

# Use this for more secret secrets, that should be only accessible by sudo

{
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    age = {
      sshKeyPaths = [
        "/home/dejanr/.ssh/id_ed25519"
      ];
      keyFile = "~/.config/sops/age/keys.txt";
      generateKey = true;
    };

    secrets = {
      openvpn_office_pass = { };
      openvpn_office_conf = { };
    };
  };
}
