{ pkgs, lib, config, ... }:

# System related secrets that are managed by agenix
# Use this for system wide secrets, that should be only accessible by sudo

{
  age.identityPaths = [ "/home/dejanr/.ssh/agenix" ];
  age.secrets.openvpn_office_pass.file = ../../../secrets/openvpn_office_pass.age;
  age.secrets.openvpn_office_pass.symlink = true;
  age.secrets.openvpn_office_conf.file = ../../../secrets/openvpn_office_conf.age;
  age.secrets.openvpn_office_conf.symlink = true;
}
