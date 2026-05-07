{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

with lib;
let
  cfg = config.modules.home.cli.pi-mono;
  jsonFormat = pkgs.formats.json { };

  pi-mono-src = inputs.pi-mono;

  packageJson = builtins.fromJSON (
    builtins.readFile (inputs.pi-mono + "/packages/coding-agent/package.json")
  );

  piMonoPkg = import ./pi-mono/nix/package.nix;
  piMono = piMonoPkg { inherit pkgs pi-mono-src; };

  piMonoExtensionsPkg = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.pi-mono-extensions;
  piBashLiveViewPkg = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.pi-bash-live-view;
  piExtensionsPkg = pkgs.runCommand "pi-extensions" { } ''
    mkdir -p $out
    for path in ${piMonoExtensionsPkg}/*; do
      ln -s "$path" "$out/$(basename "$path")"
    done
    ln -s ${piBashLiveViewPkg} $out/bash-live-view
  '';

  promptFiles = builtins.readDir ./pi-mono/prompts;
  prompts = filterAttrs (n: v: v == "regular" && hasSuffix ".md" n) promptFiles;

  settings = {
    lastChangelogVersion = packageJson.version;
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.5";
    defaultThinkingLevel = "high";
  };

  tenstorrentModels = {
    tenstorrent = {
      baseUrl = "https://console.tenstorrent.com/v1";
      api = "tenstorrent-openai";
      apiKey = "TENSTORRENT_API_KEY";
      models = [
        {
          id = "deepseek-ai/DeepSeek-R1-0528";
          name = "DeepSeek R1 0528 (Tenstorrent)";
          reasoning = true;
          thinkingLevelMap = {
            minimal = null;
            low = null;
            medium = null;
            high = "high";
            xhigh = "max";
          };
          compat = {
            supportsDeveloperRole = false;
            thinkingFormat = "deepseek";
            requiresReasoningContentOnAssistantMessages = true;
          };
        }
      ];
    };
  };

  vllmModels = {
    vllm = {
      baseUrl = "http://localhost:8080/v1";
      api = "openai-completions";
      apiKey = "vllm";
      compat = {
        supportsDeveloperRole = false;
        supportsReasoningEffort = false;
        supportsStore = false;
        supportsStrictMode = false;
        maxTokensField = "max_tokens";
        thinkingFormat = "qwen-chat-template";
      };
      models = [ ];
    };
  };

  llamaCppModels = {
    llama-cpp = {
      baseUrl = cfg.providers.llama-cpp.baseUrl;
      api = "openai-completions";
      apiKey = "llama-cpp";
      compat = {
        supportsDeveloperRole = false;
        supportsReasoningEffort = false;
        supportsStore = false;
        supportsStrictMode = false;
        maxTokensField = "max_tokens";
        thinkingFormat = "qwen-chat-template";
      };
      models = [
        {
          id = "qwen3.6-27b-mtp";
          name = "Qwen3.6 27B MTP Q4_K_M (llama.cpp)";
          reasoning = true;
          input = [ "text" ];
          contextWindow = 100000;
          maxTokens = 8192;
          cost = {
            input = 0;
            output = 0;
            cacheRead = 0;
            cacheWrite = 0;
          };
        }
      ];
    };
  };

  aiandModels = {
    aiand = {
      baseUrl = "https://api.aiand.com/v1";
      api = "openai-completions";
      apiKey = "AIAND_API_KEY";
      compat = {
        supportsDeveloperRole = false;
        supportsStore = false;
        supportsStrictMode = false;
      };
      models = [
        {
          id = "qwen/qwen3.5-9b";
          name = "Qwen3.5 9B (ai&)";
          reasoning = true;
          thinkingLevelMap.off = "none";
          input = [
            "text"
            "image"
          ];
          contextWindow = 262144;
          maxTokens = 32768;
          cost = {
            input = 0.1;
            output = 0.15;
            cacheRead = 0;
            cacheWrite = 0;
          };
        }
        {
          id = "google/gemma-3-27b-it";
          name = "Gemma 3 27B IT (ai&)";
          input = [
            "text"
            "image"
          ];
          contextWindow = 131072;
          maxTokens = 16384;
          cost = {
            input = 0.08;
            output = 0.16;
            cacheRead = 0;
            cacheWrite = 0;
          };
        }
      ];
    };
  };

  customProviders =
    optionalAttrs cfg.providers.tenstorrent.enable tenstorrentModels
    // optionalAttrs cfg.providers.aiand.enable aiandModels
    // optionalAttrs cfg.providers.vllm.enable vllmModels
    // optionalAttrs cfg.providers.llama-cpp.enable llamaCppModels;

  keybindings = {
    cursorUp = [
      "up"
    ];
    cursorDown = [
      "down"
    ];
    cursorLeft = [
      "left"
    ];
    cursorRight = [
      "right"
    ];
    toggleThinking = [
      "ctrl+t"
    ];
  };

in
{
  options.modules.home.cli.pi-mono = {
    enable = mkEnableOption "pi-mono coding agent";

    providers.tenstorrent.enable = mkEnableOption "Tenstorrent models for pi-mono";
    providers.aiand.enable = mkEnableOption "ai& models for pi-mono";
    providers.vllm.enable = mkEnableOption "local vLLM models for pi-mono";
    providers.llama-cpp = {
      enable = mkEnableOption "local llama.cpp models for pi-mono";
      baseUrl = mkOption {
        type = types.str;
        default = "http://localhost:8181/v1";
        description = "OpenAI-compatible llama.cpp server base URL.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      piMono
      pkgs.beads
    ];

    home.file = {
      ".pi/agent/settings.json".source = jsonFormat.generate "settings.json" settings;
      # ".pi/agent/keybindings.json".source = jsonFormat.generate "keybindings.json" keybindings;
      ".pi/agent/AGENTS.md".source = ./pi-mono/AGENTS.md;
      ".pi/agent/extensions".source = piExtensionsPkg;
      ".pi/agent/skills".source = ./pi-mono/skills;
      ".pi/agent/themes/dejanr.json".source = ./pi-mono/themes/dejanr.json;
    }
    // optionalAttrs (customProviders != { }) {
      ".pi/agent/models.json".source = jsonFormat.generate "models.json" {
        providers = customProviders;
      };
    }
    // (mapAttrs' (
      name: _:
      nameValuePair ".pi/agent/prompts/${name}" {
        source = ./pi-mono/prompts/${name};
      }
    ) prompts);
  };
}
