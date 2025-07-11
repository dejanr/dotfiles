{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.modules.system.roles.hosts;
  baseUrl = "https://raw.githubusercontent.com/StevenBlack/hosts";
  commit = "358526ed7866d474c9158cb61f47c8aabedb8014";
  hostsFile = pkgs.fetchurl {
    url = "${baseUrl}/${commit}/alternates/fakenews-gambling/hosts";
    sha256 = "GXjL6WFOrMi+Y0wQkkQffs7OLqa00QBfgkCH0LZ86hw=";
  };
  hostsContent = lib.readFile hostsFile;
in
{
  options.modules.system.roles.hosts = { enable = mkEnableOption "custom hosts file"; };

  config = mkIf cfg.enable {
    networking.extraHosts = hostsContent + ''
    '';
  };
}
