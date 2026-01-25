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
    defaultModel = "claude-opus-4-5";
    defaultThinkingLevel = "off";
    theme = "dejanr";
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
  };

in
{
  options.modules.home.cli.pi-mono = {
    enable = mkEnableOption "pi-mono coding agent";
  };

  config = mkIf cfg.enable {
    home.packages = [ piMono ];

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
