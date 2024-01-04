{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.git;

in {
    options.modules.git = { enable = mkEnableOption "git"; };
    config = mkIf cfg.enable {
        programs.git = {
            enable = true;
            userName = "dejanr";
            userEmail = "dejan@ranisavljevic.com";
            extraConfig = {
                branch.autosetuprebase = "always";
                color.ui = true;
                core.askPass = ""; # needs to be empty to use terminal for ask pass
                credential.helper = "store"; # want to make this more secure
                github.user = "dejanr";
                push.default = "tracking";
                init.defaultBranch = "main";
            };
        };
    };
}
