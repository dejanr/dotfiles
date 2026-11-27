{
  config,
  inputs,
  lib,
  ...
}:

let
  cfg = config.modules.home.cli.rex;
in
{
  imports = [ inputs.rex.homeManagerModules.default ];

  options.modules.home.cli.rex.enable = lib.mkEnableOption "the personal Rex server";

  config = lib.mkIf cfg.enable {
    programs.rex.sshGuard = lib.mkDefault config.programs.ssh.enable;
    services.rex.enable = true;
  };
}
