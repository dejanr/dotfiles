{
  pkgs,
  lib,
  config,
  ...
}:

with lib;

let
  cfg = config.modules.home.cli.llama-cpp;
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
      description = "Number of layers to offload to GPU (0 for CPU-only on Asahi)";
    };

    threads = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Number of threads (null for auto-detect)";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Create models directory
    home.activation.createLlamaModelsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "${cfg.modelsDir}"
    '';

    # Shell aliases for convenience
    programs.zsh.shellAliases = mkIf config.programs.zsh.enable {
      # Interactive chat
      llm-chat = concatStringsSep " " (
        [
          "llama-cli"
          "--model ${cfg.modelsDir}/\${LLAMA_MODEL:-${
            if cfg.defaultModel != null then cfg.defaultModel else "model.gguf"
          }}"
          "--ctx-size ${toString cfg.contextSize}"
          "--conversation"
        ]
        ++ optional (cfg.threads != null) "--threads ${toString cfg.threads}"
        ++ optional (cfg.gpuLayers > 0) "--n-gpu-layers ${toString cfg.gpuLayers}"
      );

      # Start server
      llm-server = concatStringsSep " " (
        [
          "llama-server"
          "--model ${cfg.modelsDir}/\${LLAMA_MODEL:-${
            if cfg.defaultModel != null then cfg.defaultModel else "model.gguf"
          }}"
          "--ctx-size ${toString cfg.contextSize}"
          "--port ${toString cfg.serverPort}"
          "--host 0.0.0.0"
        ]
        ++ optional (cfg.threads != null) "--threads ${toString cfg.threads}"
        ++ optional (cfg.gpuLayers > 0) "--n-gpu-layers ${toString cfg.gpuLayers}"
      );

      # List models
      llm-models = "ls -lh ${cfg.modelsDir}/*.gguf 2>/dev/null || echo 'No models found in ${cfg.modelsDir}'";
    };

    programs.bash.shellAliases = mkIf config.programs.bash.enable {
      llm-chat = concatStringsSep " " (
        [
          "llama-cli"
          "--model ${cfg.modelsDir}/\${LLAMA_MODEL:-${
            if cfg.defaultModel != null then cfg.defaultModel else "model.gguf"
          }}"
          "--ctx-size ${toString cfg.contextSize}"
          "--conversation"
        ]
        ++ optional (cfg.threads != null) "--threads ${toString cfg.threads}"
        ++ optional (cfg.gpuLayers > 0) "--n-gpu-layers ${toString cfg.gpuLayers}"
      );

      llm-server = concatStringsSep " " (
        [
          "llama-server"
          "--model ${cfg.modelsDir}/\${LLAMA_MODEL:-${
            if cfg.defaultModel != null then cfg.defaultModel else "model.gguf"
          }}"
          "--ctx-size ${toString cfg.contextSize}"
          "--port ${toString cfg.serverPort}"
          "--host 0.0.0.0"
        ]
        ++ optional (cfg.threads != null) "--threads ${toString cfg.threads}"
        ++ optional (cfg.gpuLayers > 0) "--n-gpu-layers ${toString cfg.gpuLayers}"
      );

      llm-models = "ls -lh ${cfg.modelsDir}/*.gguf 2>/dev/null || echo 'No models found in ${cfg.modelsDir}'";
    };
  };
}
