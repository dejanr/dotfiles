{
  pkgs,
  config,
  lib,
  ...
}:
with lib;

let
  cfg = config.modules.home.cli.yazi;

  yaziFlavors = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "fc8eeaab9da882d0e77ecb4e603b67903a94ee6e";
    sha256 = "sha256-wvxwK4QQ3gUOuIXpZvrzmllJLDNK6zqG5V2JAqTxjiY";
  };

  yaziPlugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "600614a9dc59a12a63721738498c5541c7923873";
    sha256 = "sha256-mQkivPt9tOXom78jgvSwveF/8SD8M2XCXxGY8oijl+o";
  };
in
{
  options.modules.home.cli.yazi = with types; {
    enable = mkEnableOption "yazi" // {
      default = false;
    };
  };

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      flavors = {
        catppuccin-mocha = "${yaziFlavors}/catppuccin-mocha.yazi";
      };
      plugins = {
        jump-to-char = "${yaziPlugins}/jump-to-char.yazi";
        smart-enter = "${yaziPlugins}/smart-enter.yazi";
      };
      shellWrapperName = "y";
      settings = {
        log = {
          enabled = false;
        };
        manager = {
          show_hidden = false;
          sort_by = "mtime";
          sort_dir_first = true;
          sort_reverse = true;
        };
        preview = {
          max_width = 1000;
          max_height = 1000;
        };
        show_hidden = false;
      };
      keymap = {
        manager.prepend_keymap = [
          {
            run = "plugin jump-to-char";
            on = [ "f" ];
          }
          {
            run = "plugin smart-enter";
            on = [ "l" ];
          }
          {
            run = "plugin smart-enter";
            on = [ "<Enter>" ];
          }
          {
            run = "leave";
            on = [ "-" ];
          }
        ];
      };
    };
  };
}
