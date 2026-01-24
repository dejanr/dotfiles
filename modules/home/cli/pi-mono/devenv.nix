{
  languages.javascript = {
    enable = true;
    pnpm.enable = true;
  };

  scripts.extensions-install.exec = "pnpm -C ./extensions install";
  scripts.extensions-build.exec = "pnpm -C ./extensions -r run build";
  scripts.extensions-lint.exec = "pnpm -C ./extensions run lint";
  scripts.extensions-typecheck.exec = "pnpm -C ./extensions run typecheck";
  scripts.extensions-check.exec = "pnpm -C ./extensions run check";
  scripts.extensions-sync.exec = "node ./nix/scripts/update-extensions-version.mjs";

  enterShell = ''
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  Pi-mono Development Environment                              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Commands:"
    echo "  extensions-install             - Install workspace dependencies"
    echo "  extensions-build               - Build all extensions"
    echo "  extensions-lint                - Lint the workspace"
    echo "  extensions-typecheck           - Typecheck the workspace"
    echo "  extensions-check               - Run lint + typecheck"
    echo "  extensions-sync                - Sync extension deps with pi-mono"
    echo ""
  '';
}
