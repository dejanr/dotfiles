{ config, options, lib, pkgs, ... }:

with lib; {
  options.modules.editors.vim = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.editors.vim.enable {
    my = {
      packages = with pkgs; [ vim ];

      home.programs.vim = {
        enable = true;
        extraConfig = ''
          set runtimepath=$XDG_CONFIG_HOME/vim/vim,$VIM,$VIMRUNTIME
          let $MYVIMRC='$XDG_CONFIG_HOME/vim/vimrc' | source $MYVIMRC
        '';
      };

      home.xdg.configFile."vim/vimrc".source = <config/vim/vimrc>;
      home.xdg.configFile."vim/vim".source = <config/vim/vim>;
    };
  };
}
