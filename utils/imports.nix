{ lib }:
{
  importsFrom =
    {
      path,
      exclude ? [ ],
    }:
    let
      # Separate file excludes from directory excludes
      # Paths and strings with "/" are directory excludes
      fileExcludes = builtins.filter (x: builtins.isString x && !lib.hasInfix "/" x) exclude;
      dirExcludes = builtins.filter (x: builtins.isPath x || (builtins.isString x && lib.hasInfix "/" x)) exclude;

      # Filter nix modules first
      nixModules = lib.fileset.fileFilter (
        { name, ... }:
        let
          isDefault = name == "default.nix";
          isNixModule = lib.hasSuffix ".nix" name;
          isExcluded = lib.any (pattern: lib.hasSuffix pattern name) fileExcludes;
        in
        isNixModule && !isExcluded && !isDefault
      ) path;

      # Intersect with git tracked files
      gitTrackedModules = lib.fileset.intersection (lib.fileset.gitTracked path) nixModules;

      # Remove excluded directories
      withoutDirs = builtins.foldl' (set: dir:
        let
          # Handle both string paths and actual paths
          dirPath = if builtins.isPath dir then dir else (path + ("/" + dir));
        in if builtins.pathExists dirPath
           then lib.fileset.difference set dirPath
           else set
      ) gitTrackedModules dirExcludes;
    in
    lib.fileset.toList withoutDirs;
}
