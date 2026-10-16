{ pkgs }:

let
  version = "1.8.3";
  releases = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-lZanDpIMqf0i6lQbdzwt3Gpjr0OQ2ohk69+83FlJqpc=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-iq2bNPOY8yyvsoJdwufWirLepRvQDhvsHS+4NwyFBvI=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-DMdSIr7ytdcwASQBxzzQlJLxjirRQjZFQVRHKBpWGr0=";
    };
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-g4xIe9ZGuCI/ibItLW2jTuiXK/TRfUq/6HJrMPP9rok=";
    };
  };
  release = releases.${pkgs.stdenv.hostPlatform.system};
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "cccc";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/moznion/cccc/releases/download/v${version}/cccc-v${version}-${release.target}.tar.gz";
    inherit (release) hash;
  };

  sourceRoot = ".";
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 cccc "$out/bin/cccc"
    install -Dm644 LICENSE "$out/share/licenses/cccc/LICENSE"
    install -Dm644 README.md "$out/share/doc/cccc/README.md"

    runHook postInstall
  '';

  doInstallCheck = pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform;
  nativeInstallCheckInputs = [ pkgs.jq ];
  installCheckPhase = ''
    runHook preInstallCheck

    test "$("$out/bin/cccc" --version)" = "cccc ${version}"
    printf 'function example(value) { if (value) return 1; return 0; }\n' > sample.js
    "$out/bin/cccc" --no-config --no-cache sample.js > report.json
    jq -e '
      .summary.parse_error_count == 0 and
      .summary.file_count == 1 and
      .files[0].functions[0].cognitive == 1 and
      .files[0].functions[0].cyclomatic == 2
    ' report.json

    runHook postInstallCheck
  '';

  meta = {
    description = "Measure cognitive and cyclomatic complexity across multiple languages";
    homepage = "https://github.com/moznion/cccc";
    license = pkgs.lib.licenses.mit;
    sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames releases;
    mainProgram = "cccc";
  };
}
