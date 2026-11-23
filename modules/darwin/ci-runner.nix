{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.darwin.ci-runner;
  user = "_dotfilesci";
  home = "/Users/${user}";
  runner = "${pkgs.github-runner}/bin/Runner.Listener";
  registrationArgs = [
    "--disableupdate"
    "--no-default-labels"
    "--labels"
    "isolated-macos"
    "--name"
    config.networking.hostName
    "--url"
    cfg.url
    "--work"
    "${home}/work"
  ]
  ++ lib.optionals (cfg.runnerGroup != null) [
    "--runnergroup"
    cfg.runnerGroup
  ];
  runnerPath = lib.makeBinPath (
    with pkgs;
    [
      bashInteractive
      coreutils
      git
      gnutar
      gzip
      jq
    ]
    ++ lib.optional config.nix.enable config.nix.package
  );
  externalNixPath = lib.optionalString (!config.nix.enable) ":/nix/var/nix/profiles/default/bin";
  command = pkgs.writeShellApplication {
    name = "macos-ci-runner";
    text = ''
      export PATH=${runnerPath}${externalNixPath}:/usr/bin:/bin:/usr/sbin:/sbin
      export HOME=${home}
      export RUNNER_ROOT="$HOME/.github-runner"
      umask 077

      if [[ "$(id -un)" != ${user} ]]; then
        echo 'Run this command as ${user} inside the CI guest.' >&2
        exit 1
      fi

      case "''${1:-}" in
        enroll)
          exec ${runner} configure ${lib.escapeShellArgs registrationArgs}
          ;;
        run)
          if [[ ! -f "$RUNNER_ROOT/.runner" || ! -f "$RUNNER_ROOT/.credentials" || ! -f "$RUNNER_ROOT/.credentials_rsaparams" ]]; then
            exit 0
          fi
          exec ${runner} run --startuptype service
          ;;
        *) echo 'Usage: macos-ci-runner {enroll|run}' >&2; exit 2 ;;
      esac
    '';
  };
in
{
  options.modules.darwin.ci-runner = {
    enable = lib.mkEnableOption "a GitHub Actions runner inside a macOS CI VM";
    url = lib.mkOption {
      type = lib.types.strMatching "https://github[.]com/[A-Za-z0-9-]+(/[A-Za-z0-9_.-]+)?";
      description = "The GitHub repository or organization in which to register the runner.";
    };
    runnerGroup = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
      description = "The organization runner group, if registering at organization scope.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.knownUsers = [ user ];
    users.users.${user} = {
      uid = 550;
      inherit home;
      createHome = true;
    };
    nix.settings.allowed-users = lib.mkIf config.nix.enable [ user ];

    environment.systemPackages = [ command ];

    launchd.daemons.macos-ci-runner = {
      command = "${lib.getExe command} run";
      serviceConfig = {
        UserName = user;
        RunAtLoad = true;
        KeepAlive.SuccessfulExit = false;
        ThrottleInterval = 60;
      };
    };
  };
}
