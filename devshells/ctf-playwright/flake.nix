{
  description = "CTF Playwright browsers and development shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/b6018f87da91d19d0ab4cf979885689b469cdd41";
  inputs.nodepkgs.url = "github:NixOS/nixpkgs/36173dbc6ff2b383c4d03b002fd1ea58e2e4dbcd";

  outputs =
    { nixpkgs, nodepkgs, ... }:
    let
      forEachSystem = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      environments = forEachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          nodePackages = import nodepkgs {
            inherit system;
            config.allowDeprecatedx86_64Darwin = true;
          };
          nodejs = nodePackages.nodejs_24.override {
            nodejs-slim = nodePackages.nodejs-slim_24.overrideAttrs (
              finalAttrs: oldAttrs: {
                version = "24.22.1";
                src = nodePackages.fetchurl {
                  url = "https://nodejs.org/dist/v${finalAttrs.version}/node-v${finalAttrs.version}.tar.xz";
                  hash = "sha256-T1N5eWKAza6wwvNY/QS2oWzE+336g7WoyRqdljtDUjE=";
                };
                configureFlags = builtins.filter (
                  flag: !(nodePackages.lib.hasPrefix "--shared-brotli" flag)
                ) oldAttrs.configureFlags;
                buildInputs = nodePackages.lib.remove nodePackages.brotli oldAttrs.buildInputs;
              }
            );
          };
          driver = pkgs.playwright-driver;
          browserEnvironment = {
            PLAYWRIGHT_BROWSERS_PATH = "${driver.browsers}";
            PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
          }
          // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
            PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "1";
            PLAYWRIGHT_HOST_PLATFORM_OVERRIDE =
              if system == "x86_64-linux" then "ubuntu24.04-x64" else "ubuntu24.04-arm64";
          };
          runtimeConfig = pkgs.writeText "ctf-playwright-runtime.json" (
            builtins.toJSON {
              nodeVersion = nodejs.version;
              playwrightVersion = driver.version;
              browsers = driver.browsersJSON;
            }
          );
          rushTools =
            map
              (
                name:
                pkgs.writeShellApplication {
                  inherit name;
                  runtimeInputs = [
                    nodejs
                    pkgs.git
                  ];
                  text = ''
                    root="$(git rev-parse --show-toplevel)"
                    exec node "$root/common/scripts/install-run-${name}.js" "$@"
                  '';
                }
              )
              [
                "rush"
                "rushx"
                "rush-pnpm"
              ];
          runtimeInputs = rushTools ++ [
            nodejs
            pkgs.bash
            pkgs.coreutils
            pkgs.git
            pkgs.ripgrep
            pkgs.gnugrep
            pkgs.gnused
            pkgs.gawk
          ];
          launcher = pkgs.writeShellApplication {
            name = "ctf-playwright";
            inherit runtimeInputs;
            text = ''
              ${pkgs.lib.toShellVars browserEnvironment}
              export ${builtins.concatStringsSep " " (builtins.attrNames browserEnvironment)}
              exec node ${./launcher.mjs} ${runtimeConfig} "$@"
            '';
          };
        in
        assert pkgs.lib.versionAtLeast nodejs.version "24.22.1";
        {
          inherit launcher;
          shell = pkgs.mkShell (
            browserEnvironment
            // {
              packages = runtimeInputs ++ [ launcher ];
            }
          );
          tests = pkgs.runCommand "ctf-playwright-tests" { nativeBuildInputs = [ nodejs ]; } ''
            node --test ${./.}/launcher.test.mjs
            touch "$out"
          '';
        }
      );
    in
    {
      packages = forEachSystem (system: {
        default = environments.${system}.launcher;
      });
      apps = forEachSystem (system: {
        default = {
          type = "app";
          program = "${environments.${system}.launcher}/bin/ctf-playwright";
          meta.description = "Run CTF's Playwright tests with pinned browsers";
        };
      });
      devShells = forEachSystem (system: {
        default = environments.${system}.shell;
      });
      checks = forEachSystem (system: {
        launcher = environments.${system}.tests;
      });
      formatter = forEachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
