{
  lib,
  mkObsidianPlugin,
}:

mkObsidianPlugin {
  pluginId = "remarkable-sync";
  version = "1.0.3";

  files = {
    "main.js" = {
      url = "https://github.com/TimDommett/Remarkable-Sync---Obsidian-Plugin/releases/download/1.0.3/main.js";
      hash = "sha256-SkoqGvKjfB6ua2jp6f4XW3BdSIegI6miV1G1BT60s54=";
    };

    "manifest.json" = {
      url = "https://github.com/TimDommett/Remarkable-Sync---Obsidian-Plugin/releases/download/1.0.3/manifest.json";
      hash = "sha256-rrsiHFU3hw2j4qTtg6J5/sZrLdzIX2VSszVX2nb2G/0=";
    };

    "styles.css" = {
      url = "https://github.com/TimDommett/Remarkable-Sync---Obsidian-Plugin/releases/download/1.0.3/styles.css";
      hash = "sha256-m6V6RRLxdfKXZmZamrEqRdtbirZUBJGgMBP+sCiw738=";
    };
  };

  meta = with lib; {
    description = "Obsidian plugin for syncing reMarkable documents as PDFs";
    homepage = "https://github.com/TimDommett/Remarkable-Sync---Obsidian-Plugin";
    license = licenses.gpl3Only;
    sourceProvenance = [ sourceTypes.binaryBytecode ];
  };
}
