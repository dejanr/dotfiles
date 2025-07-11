{ lib }:
{
  importsFrom = { path, exclude ? [ ] }:
    lib.fileset.toList
      (lib.fileset.intersection
        (lib.fileset.gitTracked path)
        (lib.fileset.fileFilter
          (file:
            let
              isDefault = file.name == "default.nix";
              isNixModule = lib.hasSuffix ".nix" file.name;
              isExcluded = lib.any (pattern: lib.hasSuffix pattern file.name) exclude;
            in
            isNixModule && !isExcluded && !isDefault
          )
          path
        )
      );
}

