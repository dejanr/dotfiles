{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.home.cli.ps-kill;
  psKill = pkgs.callPackage ./ps-kill { };
in
{
  options.modules.home.cli.ps-kill = {
    enable = mkEnableOption "interactive process termination with fzf";
  };

  config = mkIf cfg.enable {
    home.packages = [ psKill ];

    programs.zsh.initContent = mkIf config.programs.zsh.enable (mkAfter ''
      ps-kill-widget() {
        zle -I
        ${psKill}/bin/ps-kill </dev/tty
        zle reset-prompt
      }
      zle -N ps-kill-widget
      bindkey '^K' ps-kill-widget
    '');

    programs.bash.bashrcExtra = mkIf config.programs.bash.enable (mkAfter ''
      bind -x '"\C-k":${psKill}/bin/ps-kill </dev/tty'
    '');
  };
}
