{
  lib,
  stdenvNoCC,
  fetchurl,
}:
{
  pluginId,
  version,
  files,
  meta ? { },
}:

let
  fetchedFiles = lib.mapAttrs (_name: spec: fetchurl spec) files;
in
stdenvNoCC.mkDerivation {
  pname = "obsidian-plugin-${pluginId}";
  inherit version;

  dontUnpack = true;

  installPhase = ''
    mkdir -p "$out"

    ${lib.concatStringsSep "\n    " (
      lib.mapAttrsToList (name: src: "cp ${src} \"$out/${name}\"") fetchedFiles
    )}
  '';

  passthru.obsidianPlugin = {
    id = pluginId;
  };

  meta = {
    platforms = lib.platforms.all;
  } // meta;
}
