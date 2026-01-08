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

  extensionsDir = ./pi-mono/extensions;
  extensionDirs = builtins.readDir extensionsDir;
  extensionNames = attrNames (filterAttrs (_: v: v == "directory") extensionDirs);

  promptFiles = builtins.readDir ./pi-mono/prompts;
  prompts = filterAttrs (n: v: v == "regular" && hasSuffix ".md" n) promptFiles;

  homeDir = config.home.homeDirectory;

  settings = {
    lastChangelogVersion = packageJson.version;
    defaultProvider = "anthropic";
    defaultModel = "claude-opus-4-5";
    defaultThinkingLevel = "off";
    extensions = map (name: "${homeDir}/.pi/agent/extensions/${name}/index.ts") extensionNames;
  };

  keybindings = {
    cursorUp = [
      "up"
      "ctrl+p"
    ];
    cursorDown = [
      "down"
      "ctrl+n"
    ];
    cursorLeft = [
      "left"
      "ctrl+b"
    ];
    cursorRight = [
      "right"
      "ctrl+f"
    ];
  };

  extensionFiles = listToAttrs (
    concatMap (
      name:
      let
        extDir = extensionsDir + "/${name}";
        files = builtins.readDir extDir;
        tsFiles = attrNames (filterAttrs (n: v: v == "regular" && hasSuffix ".ts" n) files);
      in
      map (file: {
        name = ".pi/agent/extensions/${name}/${file}";
        value = { source = extDir + "/${file}"; };
      }) tsFiles
    ) extensionNames
  );
in
{
  options.modules.home.cli.pi-mono = {
    enable = mkEnableOption "pi-mono coding agent";
  };

  config = mkIf cfg.enable {
    home.packages = [ piMono ];

    home.file =
      {
        ".pi/agent/settings.json".source = jsonFormat.generate "settings.json" settings;
        ".pi/agent/keybindings.json".source = jsonFormat.generate "keybindings.json" keybindings;
        ".pi/agent/AGENTS.md".source = ./pi-mono/AGENTS.md;
      }
      // extensionFiles
      // (mapAttrs' (
        name: _:
        nameValuePair ".pi/agent/prompts/${name}" {
          source = ./pi-mono/prompts/${name};
        }
      ) prompts);
  };
}
