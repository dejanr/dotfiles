{ config, pkgs, ... }:

{
	services.znc = {
    enable = true;
    openFirewall = true;

    confOptions = {
      networks = {
        freenode = {
          channels = [
            "haskell"
            "haskell-beginners"
            "haskell-offtopic"
            "qfpl"
            "nixos"
            "ocaml"
            "reasonml"
            "reprap"
            "bigdelta"
          ];
          modules = [ "log" "simple_away" ];
          server = "chat.freenode.net";
          port = 6697;
          useSSL = true;
          userName = "dejanr";
          password = (import ../secrets.nix).ircPassword;
        };
      };

      useSSL = false;
      modules = [ "adminlog" "log" ];
      nick = "dejanr";
      port = 9000;
      # passBlock with `nix-shell -p znc --command "znc --makepass"`.
      # and place it inside secrets.nix
			passBlock = (import ../secrets.nix).zncPassBlock;
    };
  };
}
