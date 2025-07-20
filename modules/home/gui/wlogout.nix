{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.home.gui.wlogout;
  bgImageSection = name: ''
    #${name} {
      background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/${name}.png"));
    }
  '';
in
{
  options.modules.home.gui.wlogout = {
    enable = mkEnableOption "Enable wlogout";
  };

  config = mkIf cfg.enable {
    programs.wlogout = {
      enable = true;

      layout = [
        {
          label = "lock";
          action = "swaylock";
          text = "(L) Lock screen";
          keybind = "l";
        }
        {
          label = "reboot";
          action = "systemctl reboot";
          text = "(R) Reboot";
          keybind = "r";
        }
        {
          label = "shutdown";
          action = "systemctl poweroff";
          text = "(P) Power off";
          keybind = "p";
        }
      ];

      style = ''
        * {
        	background-image: none;
        }
        window {
        	background-color: rgba(108, 112, 134, 0.5);
        }
        button {
          color: #cdd6f4;
        	font-size: 16px;
          font-weight: bold;
        	background-color: #7f849c;
        	border-style: none;
        	background-repeat: no-repeat;
        	background-position: center;
        	background-size: 20%;
        	border-radius:30px;
        	margin: 300px 20px;
        	text-shadow: 0px 0px;
        	box-shadow: 0px 0px;
        }

        button:focus, button:active, button:hover {
        	background-color: #9399b2;
        	outline-style: none;
        }

        ${lib.concatMapStringsSep "\n" bgImageSection [
          "lock"
          "logout"
          "suspend"
          "hibernate"
          "shutdown"
          "reboot"
        ]}
      '';
    };
  };
}
