{
  description = "CTF Playwright browsers and development shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/b6018f87da91d19d0ab4cf979885689b469cdd41";

  outputs =
    { nixpkgs, ... }:
    let
      forEachSystem = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      environments = forEachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          nodejs = pkgs.nodejs_24;
          driver = pkgs.playwright-driver;
          browserEnvironment = {
            PLAYWRIGHT_BROWSERS_PATH = "${driver.browsers}";
            PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
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
        assert pkgs.lib.versionAtLeast nodejs.version "24.11.0";
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
