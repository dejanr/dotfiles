# Pi-mono Extensions

This directory contains pi-mono extensions packaged as pnpm workspaces. Each extension lives in its own folder with an `index.ts` and `package.json`, and the workspace root provides shared TypeScript + ESLint configuration.

## Layout

```
modules/home/cli/pi-mono/extensions/
├── package.json          # Workspace root (dev deps + scripts)
├── pnpm-workspace.yaml   # Workspace definition
├── tsconfig.json         # Shared TS config
├── eslint.config.mjs      # Shared ESLint config
├── <extension>/
│   ├── index.ts
│   └── package.json
```

## Quick Start

```bash
cd modules/home/cli/pi-mono/extensions
# Install workspace + extension deps
pnpm install
pnpm run typecheck
pnpm run lint
```

## Adding a New Extension

1. Create a new folder under `modules/home/cli/pi-mono/extensions/<name>`.
2. Add an `index.ts` with a default export function.
3. Add a `package.json` with a `pi.extensions` entry and the shared build script (`nix/scripts/build.mjs`).

Example `package.json`:

```json
{
  "name": "pi-extension-foo",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "pi": {
    "extensions": ["./dist/index.js"]
  },
  "peerDependencies": {
    "@mariozechner/pi-coding-agent": "*"
  },
  "scripts": {
    "build": "node ../../nix/scripts/build.mjs"
  }
}
```

## Testing Extensions

- **Typecheck:** `pnpm run typecheck`
- **Lint:** `pnpm run lint`
- **Build all extensions:** `nix develop -c bash -lc "cd modules/home/cli/pi-mono/extensions && pnpm install && pnpm run build"`

To test an extension in pi:

```bash
pi -e ./modules/home/cli/pi-mono/extensions/<name>/index.ts
```

Notes:
- Dependencies shared across extensions should be declared at the workspace root (`package.json`).
- Runtime dependencies specific to an extension should be listed in that extension’s `package.json` under `dependencies`.
- Peer dependencies are automatically marked as externals by the shared build script.
- The final extension builds are packaged via Nix (`modules/home/cli/pi-mono/nix/extensions.nix`), but this workspace setup supports local development and testing too.
