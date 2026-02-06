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

  piMonoExtensionsPkg = inputs.self.packages.${pkgs.system}.pi-mono-extensions;

  promptFiles = builtins.readDir ./pi-mono/prompts;
  prompts = filterAttrs (n: v: v == "regular" && hasSuffix ".md" n) promptFiles;

  settings = {
    lastChangelogVersion = packageJson.version;
    defaultProvider = "anthropic";
    defaultModel = "claude-opus-4-6";
    defaultThinkingLevel = "off";
  };

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

    voiceInput = {
      device = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "PulseAudio/PipeWire input device for voice recording. Auto-detected if null.";
        example = "alsa_input.platform-sound.HiFi__Headset__source";
      };

      language = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "ISO-639-1/3 language code for speech recognition.";
        example = "en";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      piMono
      pkgs.beads
    ];

    home.sessionVariables = mkMerge [
      (mkIf (cfg.voiceInput.device != null) {
        PULSE_INPUT_DEVICE = cfg.voiceInput.device;
      })
      (mkIf (cfg.voiceInput.language != null) {
        ELEVENLABS_LANGUAGE = cfg.voiceInput.language;
      })
    ];

    home.file = {
      ".pi/agent/settings.json".source = jsonFormat.generate "settings.json" settings;
      ".pi/agent/keybindings.json".source = jsonFormat.generate "keybindings.json" keybindings;
      ".pi/agent/AGENTS.md".source = ./pi-mono/AGENTS.md;
      ".pi/agent/extensions".source = piMonoExtensionsPkg;
      ".pi/agent/skills".source = ./pi-mono/skills;
      ".pi/agent/themes/dejanr.json".source = ./pi-mono/themes/dejanr.json;
    }
    // (mapAttrs' (
      name: _:
      nameValuePair ".pi/agent/prompts/${name}" {
        source = ./pi-mono/prompts/${name};
      }
    ) prompts);
  };
}
