{ pkgs }:

let
  upstreamSrc = pkgs.fetchFromGitHub {
    owner = "offbynan";
    repo = "pi-cursor-provider";
    rev = "84faa1dd2c3ce306547961c67b5c4194ca7c57ac";
    hash = "sha256-wBqW4QPEj+6YRmSn3C3UnwGziGZAXZP7zZ0vlu6YIoU=";
  };

  packageJson = builtins.fromJSON (builtins.readFile (upstreamSrc + "/package.json"));
  buildPackageJson = packageJson // {
    dependencies = {
      "@bufbuild/protobuf" = "2.11.0";
    };
    devDependencies = { };
    peerDependencies = { };
  };
  runtimePackageJson = packageJson // {
    pi = packageJson.pi // {
      extensions = [ "./dist/index.js" ];
    };
  };

  packageJsonFile = pkgs.writeText "pi-cursor-provider-package.json" (
    builtins.toJSON buildPackageJson
  );
  runtimePackageJsonFile = pkgs.writeText "pi-cursor-provider-runtime-package.json" (
    builtins.toJSON runtimePackageJson
  );
  packageLockFile = pkgs.writeText "pi-cursor-provider-package-lock.json" (
    builtins.toJSON {
      name = packageJson.name;
      version = packageJson.version;
      lockfileVersion = 3;
      requires = true;
      packages = {
        "" = {
          name = packageJson.name;
          version = packageJson.version;
          license = packageJson.license;
          dependencies = buildPackageJson.dependencies;
        };
        "node_modules/@bufbuild/protobuf" = {
          version = "2.11.0";
          resolved = "https://registry.npmjs.org/@bufbuild/protobuf/-/protobuf-2.11.0.tgz";
          integrity = "sha512-sBXGT13cpmPR5BMgHE6UEEfEaShh5Ror6rfN3yEK5si7QVrtZg8LEPQb0VVhiLRUslD2yLnXtnRzG035J/mZXQ==";
          license = "(Apache-2.0 AND BSD-3-Clause)";
        };
      };
    }
  );

  src = pkgs.runCommand "pi-cursor-provider-source" { } ''
    cp -r ${upstreamSrc} $out
    chmod -R u+w $out
    cp ${packageJsonFile} $out/package.json
    cp ${packageLockFile} $out/package-lock.json
  '';
in
pkgs.buildNpmPackage {
  pname = "pi-cursor-provider";
  inherit (packageJson) version;
  inherit src;

  npmDepsHash = "sha256-JMyD8phC+mS1/nwom99pYdkbNuV8Jrs76vYbPwVf1Vo=";
  npmDepsFetcherVersion = 2;

  nodejs = pkgs.nodejs_24;
  nativeBuildInputs = [ pkgs.esbuild ];

  buildPhase = ''
    runHook preBuild

    esbuild index.ts \
      --bundle \
      --platform=node \
      --format=esm \
      --target=node22 \
      --outfile=dist/index.js

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/dist
    cp dist/index.js h2-bridge.mjs $out/dist/
    cp README.md LICENSE $out/
    cp ${runtimePackageJsonFile} $out/package.json

    runHook postInstall
  '';

  meta = {
    description = packageJson.description;
    homepage = packageJson.homepage;
    license = pkgs.lib.licenses.mit;
  };
}
