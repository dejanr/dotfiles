{ config, pkgs, ... }:

{
	users.users.valheim = {
		home = "/var/lib/valheim";
		isSystemUser = true;
	};

  networking.firewall.allowedTCPPorts = [ 2456 2457 ];
  networking.firewall.allowedUDPPorts = [ 2456 2457 ];

	systemd.services.valheim = {
		wantedBy = [ "multi-user.target" ];
		serviceConfig = {
			ExecStartPre = ''
				${pkgs.steamcmd}/bin/steamcmd \
					+login anonymous \
					+force_install_dir $STATE_DIRECTORY \
					+app_update 896660 \
					+quit
			'';
			ExecStart = ''
				${pkgs.glibc}/lib/ld-linux-x86-64.so.2 ./valheim_server.x86_64 \
					-name "Rani Wunderland" \
					-port 2456 \
					-world "Wunderland" \
					-password "12345" \
					-public 1
			'';
			Nice = "-5";
			Restart = "always";
			StateDirectory = "valheim";
			User = "valheim";
			WorkingDirectory = "/var/lib/valheim";
		};
		environment = {
			LD_LIBRARY_PATH = "linux64:${pkgs.glibc}/lib";
		};
	};
}

