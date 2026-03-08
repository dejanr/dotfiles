{
  pkgs,
  lib,
  config,
  ...
}:

with lib;

let
  cfg = config.modules.home.cli.llama-cpp;
  modelPath = "${cfg.modelsDir}/\${LLAMA_MODEL:-${if cfg.defaultModel != null then cfg.defaultModel else "model.gguf"}}";
  envPrefix = optionalString (cfg.extraEnv != { }) (
    "env "
    + concatStringsSep " " (mapAttrsToList (name: value: "${name}=${escapeShellArg value}") cfg.extraEnv)
  );
  commandPrefix = command: concatStringsSep " " (filter (part: part != "") [ envPrefix command ]);
  commonArgs =
    [
      "--model ${modelPath}"
      "--ctx-size ${toString cfg.contextSize}"
    ]
    ++ optional cfg.flashAttention "-fa 1"
    ++ optional cfg.noMmap "--no-mmap"
    ++ optional (cfg.threads != null) "--threads ${toString cfg.threads}"
    ++ optional (cfg.gpuLayers > 0) "--n-gpu-layers ${toString cfg.gpuLayers}"
    ++ cfg.extraArgs;
in
{
  options.modules.home.cli.llama-cpp = {
    enable = mkEnableOption "llama-cpp for local LLM inference";

    package = mkOption {
      type = types.package;
      default = pkgs.llama-cpp;
      description = "The llama-cpp package to use";
    };

    modelsDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.local/share/llama-cpp/models";
      description = "Directory to store GGUF model files";
    };

    defaultModel = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "llama-3.2-3b-instruct.Q4_K_M.gguf";
      description = "Default model filename to use";
    };

    serverPort = mkOption {
      type = types.port;
      default = 8080;
      description = "Port for llama-server";
    };

    contextSize = mkOption {
      type = types.int;
      default = 8192;
      description = "Context size (tokens) - higher uses more memory";
    };

    gpuLayers = mkOption {
      type = types.int;
      default = 0;
      description = "Number of layers to offload to GPU";
    };

    threads = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Number of threads (null for auto-detect)";
    };

    flashAttention = mkOption {
      type = types.bool;
      default = false;
      description = "Enable flash attention in aliases";
    };

    noMmap = mkOption {
      type = types.bool;
      default = false;
      description = "Disable mmap in aliases";
    };

    extraEnv = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Environment variables prefixed to llama-cpp aliases";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra arguments appended to llama-cpp aliases";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.activation.createLlamaModelsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "${cfg.modelsDir}"
    '';

    programs.zsh.shellAliases = mkIf config.programs.zsh.enable {
      llm-chat = concatStringsSep " " (
        [
          (commandPrefix "llama-cli")
        ]
        ++ commonArgs
        ++ [ "--conversation" ]
      );

      llm-server = concatStringsSep " " (
        [
          (commandPrefix "llama-server")
        ]
        ++ commonArgs
        ++ [
          "--port ${toString cfg.serverPort}"
          "--host 0.0.0.0"
        ]
      );

      llm-models = "ls -lh ${cfg.modelsDir}/*.gguf 2>/dev/null || echo 'No models found in ${cfg.modelsDir}'";
    };

    programs.bash.shellAliases = mkIf config.programs.bash.enable {
      llm-chat = concatStringsSep " " (
        [
          (commandPrefix "llama-cli")
        ]
        ++ commonArgs
        ++ [ "--conversation" ]
      );

      llm-server = concatStringsSep " " (
        [
          (commandPrefix "llama-server")
        ]
        ++ commonArgs
        ++ [
          "--port ${toString cfg.serverPort}"
          "--host 0.0.0.0"
        ]
      );

      llm-models = "ls -lh ${cfg.modelsDir}/*.gguf 2>/dev/null || echo 'No models found in ${cfg.modelsDir}'";
    };
  };
}
