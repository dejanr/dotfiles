{
  lib,
  pkgs,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.nixos.roles.hosts;
  baseUrl = "https://raw.githubusercontent.com/StevenBlack/hosts";
  commit = "358526ed7866d474c9158cb61f47c8aabedb8014";
  hostsFile = pkgs.fetchurl {
    url = "${baseUrl}/${commit}/alternates/fakenews-gambling/hosts";
    sha256 = "GXjL6WFOrMi+Y0wQkkQffs7OLqa00QBfgkCH0LZ86hw=";
  };
  hostsContent = lib.readFile hostsFile;
in
{
  options.modules.nixos.roles.hosts = {
    enable = mkEnableOption "custom hosts file";
  };

  config = mkIf cfg.enable {
    networking.extraHosts = hostsContent + ''
      127.0.0.1 dej.li.dev
      127.0.0.1 dejan.ranisavljevic.com.dev
    '';
  };
}
