{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.darwin.ci-vm;
  home = config.users.users.${config.system.primaryUser}.home;
  name = "mbp-work-ci";
  helperDir = "/Library/PrivilegedHelperTools/dotfiles-ci";
  helper = "${helperDir}/softnet";
  softnet = "${pkgs.softnet}/bin/softnet";
  tart = lib.getExe pkgs.tart;
  ipsw = {
    url = "https://updates.cdn-apple.com/2026SummerFCS/fullrestores/140-75212/A2A24B94-1FC1-45A3-93F7-C51B02AF1F4D/UniversalMac_26.6.2_25G83_Restore.ipsw";
    sha256 = "885503b7f4b06609e9a512f2befd40f59730640a3f1233e3892d60affdd51c95";
  };
  launcher = pkgs.writeShellApplication {
    name = "macos-ci-vm";
    text = ''
      export PATH=${helperDir}:/usr/bin:/bin:/usr/sbin:/sbin
      export TART_HOME=${lib.escapeShellArg "${home}/.tart"}

      if [[ $EUID == 0 ]]; then
        echo 'Run macos-ci-vm as the Mac login user, not with sudo.' >&2
        exit 1
      fi

      provision() {
        umask 077
        mkdir -p "$TART_HOME"
        chmod 0700 "$TART_HOME"
        if [[ ! -e "$TART_HOME/vms/${name}" ]]; then
          image="$TART_HOME/cache/IPSWs/sha256:${ipsw.sha256}.ipsw"
          if [[ ! -f "$image" ]]; then
            mkdir -p "$(dirname "$image")"
            curl -qfL --proto '=https' --proto-redir '=https' --continue-at - \
              --output "$image.partial" ${lib.escapeShellArg ipsw.url}
            printf '%s  %s\n' ${ipsw.sha256} "$image.partial" | shasum -a 256 -c
            mv "$image.partial" "$image"
          else
            printf '%s  %s\n' ${ipsw.sha256} "$image" | shasum -a 256 -c
          fi
          ${tart} create ${name} --from-ipsw "$image" --disk-size ${toString cfg.diskGiB}
        fi
        ${tart} set ${name} --cpu ${toString cfg.vcpus} --memory ${toString cfg.memoryMiB}
      }

      case "''${1:-}" in
        provision) provision; exit ;;
        run) graphics=() ;;
        headless) graphics=(--no-graphics) ;;
        *) echo 'Usage: macos-ci-vm {provision|run|headless}' >&2; exit 2 ;;
      esac

      if [[ ! -x ${helper} || "$(stat -f '%Su:%Sg:%Mp%Lp' ${helper})" != root:admin:4750 ]] \
        || ! cmp -s ${helper} ${softnet}; then
        echo 'Activate the host nix-darwin configuration to install the pinned Softnet helper.' >&2
        exit 1
      fi

      if [[ $(id -gn) == "$(id -g)" ]]; then
        if ! id -G | tr ' ' '\n' | grep -Fx 80 >/dev/null; then
          echo 'Softnet needs a named primary group; this user is not in the macOS admin group.' >&2
          exit 1
        fi
        printf 'exec %q %q\n' "$0" "$1" | /usr/bin/newgrp admin
        exit
      fi

      exec /usr/bin/caffeinate -s ${tart} run ${name} "''${graphics[@]}" \
        --no-audio --no-clipboard --net-softnet-block=@host,100.64.0.0/10
    '';
  };
in
{
  options.modules.darwin.ci-vm = {
    enable = lib.mkEnableOption "a dedicated macOS Tart VM for CI";
    autoStart = lib.mkEnableOption "starting the provisioned CI VM at macOS login";
    vcpus = lib.mkOption {
      type = lib.types.ints.positive;
      default = 8;
      description = "Number of virtual CPUs configured by provision.";
    };
    memoryMiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 16384;
      description = "Guest memory in MiB configured by provision.";
    };
    diskGiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 128;
      description = "Disk capacity for newly provisioned VMs; existing disks are left intact.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.tart
      launcher
    ];
    system.build.macosCiVm = launcher;

    system.activationScripts.extraActivation.text = ''
      (
        /usr/bin/install -d -o root -g wheel -m 0755 ${helperDir} || exit 1
        if [[ "$(/usr/bin/stat -f '%Su:%Sg:%Mp%Lp' ${helper} 2>/dev/null)" != root:admin:4750 ]] \
          || ! /usr/bin/cmp -s ${helper} ${softnet}; then
          temp=$(/usr/bin/mktemp ${helperDir}/.softnet.XXXXXXXX) || exit 1
          trap '/bin/rm -f "$temp"' EXIT
          /usr/bin/install -o root -g admin -m 4750 ${softnet} "$temp" || exit 1
          /bin/mv -f "$temp" ${helper} || exit 1
        fi
      ) || exit 1
    '';

    launchd.user.agents.macos-ci-vm = lib.mkIf cfg.autoStart {
      command = "${lib.getExe launcher} headless";
      serviceConfig = {
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 60;
        StandardOutPath = "${home}/Library/Logs/macos-ci-vm.log";
        StandardErrorPath = "${home}/Library/Logs/macos-ci-vm.log";
      };
    };
  };
}
