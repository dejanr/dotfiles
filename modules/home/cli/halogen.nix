{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.cli.halogen;
  quote = value: builtins.toJSON (lib.replaceStrings [ "%" ] [ "%%" ] value);
  useToken = cfg.download && cfg.hfTokenFile != null;
  tokenSource = lib.replaceStrings [ "\${XDG_RUNTIME_DIR}" ] [ "%t" ] (
    lib.replaceStrings [ "%" ] [ "%%" ] cfg.hfTokenFile
  );
  environment = {
    HF_HUB_DISABLE_PROGRESS_BARS = "1";
    HF_HUB_DISABLE_UPDATE_CHECK = "1";
    NO_COLOR = "1";
    HALOGEN_MODEL_ID = "halogen-qwen3.8-flash-next";
    HALOGEN_CTX = toString cfg.contextSize;
    HALOGEN_MAX_TOKENS_CAP = toString cfg.maxTokens;
    HALOGEN_MAX_TOKENS_DEFAULT = toString cfg.maxTokens;
    HALOGEN_KV_POOL_POSITIONS = toString cfg.kvPoolPositions;
    HALOGEN_KV_SLOTS = toString cfg.slots;
    HALOGEN_MAX_TOK = toString cfg.prefillTokens;
    HALOGEN_HOST_RESERVE_GIB = toString cfg.hostReserveGiB;
  }
  // lib.optionalAttrs cfg.download {
    HALOGEN_DOWNLOAD = "peonist-ai/halogen-qwen3.8-flash-next";
  }
  // lib.optionalAttrs useToken {
    HF_TOKEN_PATH = "/run/secrets/huggingface-token";
  };

  bootstrap = pkgs.writeText "halogen-bootstrap.sh" ''
    #!/bin/bash
    set -euo pipefail
    models=$1
    entrypoint=$2
    required=(
      qwen38-flash-next-w4b.hgn
      qwen38-flash-next-w4b.overlay.hgn
      tokenizer/tokenizer.json
      tokenizer/tokenizer_config.json
      tokenizer/chat_template.jinja
    )
    for file in "''${required[@]}"; do
      if [[ ! -s "$models/$file" ]]; then
        if [[ -z "''${HALOGEN_DOWNLOAD:-}" ]]; then
          echo "Halogen is missing $models/$file; enable downloads or complete the model directory first." >&2
          exit 1
        fi
        echo "Fetching missing Halogen files into $models (about 118 GiB for a fresh download; interrupted transfers resume)."
        HF_HUB_OFFLINE=0 hf download "$HALOGEN_DOWNLOAD" --local-dir "$models" \
          --include qwen38-flash-next-w4b.hgn \
          --include qwen38-flash-next-w4b.overlay.hgn \
          --include 'tokenizer/*'
        echo "Halogen download finished; checking required files."
        break
      fi
    done
    for file in "''${required[@]}"; do
      if [[ ! -s "$models/$file" ]]; then
        echo "Halogen download is incomplete: $models/$file is missing or empty. Restart to resume." >&2
        exit 1
      fi
    done
    exec "$entrypoint"
  '';

  prepare = pkgs.writeShellApplication {
    name = "halogen-prepare";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      kernel=$(uname -r)
      if [[ "''${kernel%%.*}" -lt 7 ]]; then
        echo "Halogen requires a supported kernel (7.0 or newer); running $kernel. Rebuild and reboot first." >&2
        exit 1
      fi
      for device in /dev/kfd /dev/dri/renderD*; do
        if [[ ! -r "$device" || ! -w "$device" ]]; then
          echo "Halogen needs read/write access to $device. Check NixOS GPU permissions and log in again." >&2
          exit 1
        fi
      done
      if [[ $(ulimit -Hl) != unlimited ]]; then
        echo "Halogen needs unlimited memlock in the systemd user manager. Apply the NixOS prerequisite and reboot." >&2
        exit 1
      fi
      mkdir -p -- ${lib.escapeShellArg cfg.modelsDir}
    '';
  };

  control =
    name: text:
    pkgs.writeShellApplication {
      inherit name text;
      runtimeInputs = [ pkgs.systemd ];
    };

  quadlet = lib.generators.toINI { listsAsDuplicateKeys = true; } {
    Unit.Description = "Halogen Qwen3.8 Flash Next local inference";
    Container = {
      Image = quote cfg.image;
      ContainerName = "halogen";
      GlobalArgs = "--remote=false --runtime=${pkgs.crun}/bin/crun";
      AddDevice = [
        "/dev/kfd"
        "/dev/dri"
      ];
      GroupAdd = "keep-groups";
      PodmanArgs = "--ipc=host";
      Ulimit = "memlock=-1:-1";
      PublishPort = "127.0.0.1:${toString cfg.port}:8731";
      Volume = [
        (lib.replaceStrings [ "%" ] [ "%%" ]
          "${cfg.modelsDir}:/models:${if cfg.download then "rw" else "ro"}"
        )
        "${bootstrap}:/halogen-bootstrap.sh:ro"
      ]
      ++ lib.optional useToken "%d/huggingface-token:/run/secrets/huggingface-token:ro";
      Entrypoint = "/bin/bash";
      Exec = "/halogen-bootstrap.sh /models /usr/local/bin/entrypoint.sh";
      Environment = lib.mapAttrsToList (name: value: quote "${name}=${value}") (
        environment // cfg.extraEnvironment
      );
      Pull = "missing";
      LogDriver = "journald";
    };
    Service = {
      Environment = quote "PATH=/run/wrappers/bin:/run/current-system/sw/bin:${
        lib.makeBinPath [
          pkgs.coreutils
          pkgs.systemd
        ]
      }";
      ExecStartPre = lib.getExe prepare;
      LimitMEMLOCK = "infinity";
      LoadCredential = lib.optional useToken "huggingface-token:${tokenSource}";
      Restart = "no";
      TimeoutStartSec = "infinity";
      TimeoutStopSec = 120;
    };
    Install.WantedBy = lib.optional cfg.autoStart "default.target";
  };
in
{
  options.modules.home.cli.halogen = {
    enable = lib.mkEnableOption "Halogen Qwen3.8 Flash Next on AMD Strix Halo";

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Start at the next systemd user-manager startup, not during Home Manager activation. Boot startup requires user lingering.";
    };

    download = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Download missing weights when starting Halogen. Disable for offline serving with a read-only models mount.";
    };

    hfTokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Runtime file containing a raw Hugging Face token, such as an agenix secret path. Loaded as a systemd credential and mounted read-only for downloads; never read into the Nix store.";
    };

    image = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/peonist-ai/halogen-flash-server:0.9.1@sha256:2322c4d91cd90aae628ac02f7dfd158f078b59789786cdb3297a7bcba2eb0cea";
      description = "Halogen container image, pinned by digest. Pulled only on startup, never during a rebuild.";
    };

    modelsDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.dataHome}/halogen/models";
      description = "Absolute directory for persistent model files and resumable downloads outside the Nix store.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8731;
      description = "Localhost-only OpenAI-compatible API port.";
    };

    contextSize = lib.mkOption {
      type = lib.types.ints.between 1 262144;
      default = 65536;
      description = "Maximum context per request, including generated tokens.";
    };

    maxTokens = lib.mkOption {
      type = lib.types.ints.between 1 65536;
      default = 16384;
      description = "Default and maximum output budget, including reasoning.";
    };

    kvPoolPositions = lib.mkOption {
      type = lib.types.ints.between 1 1048576;
      default = cfg.contextSize;
      defaultText = lib.literalExpression "config.modules.home.cli.halogen.contextSize";
      description = "Shared resident attention positions. More positions consume memory otherwise available to the desktop and file cache.";
    };

    slots = lib.mkOption {
      type = lib.types.ints.between 1 64;
      default = 1;
      description = "Concurrent generating conversations sharing the KV pool.";
    };

    prefillTokens = lib.mkOption {
      type = lib.types.ints.between 1 32768;
      default = 16384;
      description = "Maximum prefill chunk; sizes the scratch arena independently of context size.";
    };

    hostReserveGiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 24;
      description = "Host memory reserve used by Halogen's automatic pool fitting; not a hard memory-isolation guarantee.";
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        HALOGEN_VERBOSE = "1";
      };
      description = "Additional public Halogen flags. Managed model, download, network and token settings cannot be overridden here. Do not put secrets in these store-backed values.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
        message = "Halogen requires native x86_64 Linux with AMD Strix Halo (gfx1151).";
      }
      {
        assertion =
          builtins.match "/[^:\n\r]*" cfg.modelsDir != null
          && cfg.modelsDir != "/nix/store"
          && !(lib.hasPrefix "/nix/store/" cfg.modelsDir);
        message = "Halogen modelsDir must be an absolute writable data path outside the Nix store.";
      }
      {
        assertion =
          cfg.maxTokens < cfg.contextSize
          && cfg.prefillTokens <= cfg.contextSize
          && cfg.kvPoolPositions >= cfg.contextSize;
        message = "Halogen requires maxTokens < contextSize, prefillTokens <= contextSize, and kvPoolPositions >= contextSize.";
      }
      {
        assertion =
          lib.intersectLists (builtins.attrNames cfg.extraEnvironment) (
            builtins.attrNames environment
            ++ [
              "HF_TOKEN"
              "HF_TOKEN_PATH"
              "HALOGEN_DOWNLOAD"
              "HALOGEN_API_PORT"
              "HALOGEN_PORT"
              "HALOGEN_BIND"
              "HALOGEN_ENGINE"
              "HALOGEN_CHECKPOINT"
              "HALOGEN_VISION_TOWER"
            ]
          ) == [ ];
        message = "Use Halogen's module options instead of overriding managed model, download, network or token settings in extraEnvironment.";
      }
    ];

    xdg.configFile."containers/systemd/halogen.container".text = quadlet;

    home.packages = [
      pkgs.podman
      (control "halogen-start" ''
        systemctl --user daemon-reload
        systemctl --user start --no-block halogen.service
        echo "Halogen startup queued. Follow halogen-logs; the API is not ready until /health succeeds."
      '')
      (control "halogen-stop" ''
        exec systemctl --user stop halogen.service
      '')
      (control "halogen-status" ''
        exec systemctl --user status halogen.service "$@"
      '')
      (control "halogen-logs" ''
        exec journalctl --user -u halogen.service -f "$@"
      '')
    ];
  };
}
