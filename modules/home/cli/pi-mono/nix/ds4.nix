{ pkgs }:

let
  lib = pkgs.lib;
  sourceDir = ../extensions/ds4/vendor/ds4;
  source = lib.cleanSourceWith {
    src = sourceDir;
    filter = path: type:
      let
        name = baseNameOf path;
      in
      !builtins.elem name [
        ".git"
        "dist"
        "node_modules"
        ".direnv"
        ".devenv"
        "ds4"
        "ds4-server"
        "ds4_native"
        "ds4_test"
      ]
      && !(type == "regular" && lib.hasSuffix ".o" name);
  };

  metalEnv = {
    DS4_METAL_FLASH_ATTN_SOURCE = "metal/flash_attn.metal";
    DS4_METAL_DENSE_SOURCE = "metal/dense.metal";
    DS4_METAL_MOE_SOURCE = "metal/moe.metal";
    DS4_METAL_DSV4_HC_SOURCE = "metal/dsv4_hc.metal";
    DS4_METAL_UNARY_SOURCE = "metal/unary.metal";
    DS4_METAL_DSV4_KV_SOURCE = "metal/dsv4_kv.metal";
    DS4_METAL_DSV4_ROPE_SOURCE = "metal/dsv4_rope.metal";
    DS4_METAL_DSV4_MISC_SOURCE = "metal/dsv4_misc.metal";
    DS4_METAL_ARGSORT_SOURCE = "metal/argsort.metal";
    DS4_METAL_CPY_SOURCE = "metal/cpy.metal";
    DS4_METAL_CONCAT_SOURCE = "metal/concat.metal";
    DS4_METAL_GET_ROWS_SOURCE = "metal/get_rows.metal";
    DS4_METAL_SUM_ROWS_SOURCE = "metal/sum_rows.metal";
    DS4_METAL_SOFTMAX_SOURCE = "metal/softmax.metal";
    DS4_METAL_REPEAT_SOURCE = "metal/repeat.metal";
    DS4_METAL_GLU_SOURCE = "metal/glu.metal";
    DS4_METAL_NORM_SOURCE = "metal/norm.metal";
    DS4_METAL_BIN_SOURCE = "metal/bin.metal";
    DS4_METAL_SET_ROWS_SOURCE = "metal/set_rows.metal";
  };

  envExports = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: relativePath: ''export ${name}="$out/share/ds4/${relativePath}"'') metalEnv
  );
in
if !pkgs.stdenv.isDarwin then
  pkgs.runCommandNoCC "pi-mono-ds4-unsupported" { } ''
    mkdir -p "$out"
  ''
else
  pkgs.stdenv.mkDerivation {
    pname = "pi-mono-ds4";
    version = "0.1.0";

    src = source;

    buildInputs = [ pkgs.apple-sdk_15 ];

    buildPhase = ''
      runHook preBuild
      make ds4 ds4-server
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/libexec" "$out/share/ds4"

      install -m755 ds4 "$out/libexec/ds4"
      install -m755 ds4-server "$out/libexec/ds4-server"

      cp -R metal "$out/share/ds4/"
      install -m644 LICENSE "$out/share/ds4/LICENSE"
      install -m644 README.md "$out/share/ds4/README.md"
      install -m644 AGENT.md "$out/share/ds4/AGENT.md"
      install -m755 download_model.sh "$out/share/ds4/download_model.sh"
      install -m755 ds4-watchdog.sh "$out/share/ds4/ds4-watchdog.sh"

      cat > "$out/bin/ds4" <<EOF
      #!/bin/sh
      set -eu
      ${envExports}
      exec "$out/libexec/ds4" "\$@"
      EOF
      chmod +x "$out/bin/ds4"

      cat > "$out/bin/ds4-server" <<EOF
      #!/bin/sh
      set -eu
      ${envExports}
      exec "$out/libexec/ds4-server" "\$@"
      EOF
      chmod +x "$out/bin/ds4-server"

      runHook postInstall
    '';

    meta = {
      description = "Darwin package for local DeepSeek V4 Flash ds4 runtime";
      homepage = "https://github.com/mitsuhiko/DS4";
      license = lib.licenses.mit;
      platforms = lib.platforms.darwin;
      mainProgram = "ds4-server";
    };
  }
