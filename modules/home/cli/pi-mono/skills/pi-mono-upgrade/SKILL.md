---
name: pi-mono-upgrade
description: "Upgrade pi-mono coding agent in NixOS/nix-darwin dotfiles. Updates flake input, package hashes, and extension dependencies."
---

# Pi-mono Upgrade Skill

Upgrade the pi-mono coding agent package in a Nix-based dotfiles repository.

## Quick Reference

```bash
# Check current version
pi --version

# Check latest version
curl -s "https://api.github.com/repos/badlogic/pi-mono/tags?per_page=1" | jq -r '.[0].name'

# Update flake input
nix flake update pi-mono

# Build to verify (after updating hashes)
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```

## Upgrade Workflow

### 1. Check Versions

```bash
# Current version
pi --version

# Latest available
curl -s "https://api.github.com/repos/badlogic/pi-mono/tags?per_page=5" | jq -r '.[].name'
```

### 2. Update Flake Input

```bash
nix flake update pi-mono
```

This updates `flake.lock` with the new revision.

### 3. Update Package Hash

The package is defined in `modules/home/cli/pi-mono/nix/package.nix`.

To get the new `npmDepsHash`:

```bash
# Build prefetch-npm-deps tool
nix-build '<nixpkgs>' -A prefetch-npm-deps --no-out-link

# Find the pi-mono source path from derivation
nix derivation show /nix/store/*-pi-mono-coding-agent-*-npm-deps.drv 2>/dev/null | jq -r '.[].inputSrcs[]' | grep source | head -1

# Calculate hash (replace paths accordingly)
<prefetch-npm-deps-path>/bin/prefetch-npm-deps <source-path>/package-lock.json
```

Update `npmDepsHash` in `package.nix` with the new hash.

### 4. Update Extensions

Extensions are in `modules/home/cli/pi-mono/extensions/`.

Update `package.json` devDependencies to match the new version:

```json
{
  "devDependencies": {
    "@mariozechner/pi-ai": "<new-version>",
    "@mariozechner/pi-coding-agent": "<new-version>",
    "@mariozechner/pi-tui": "<new-version>"
  }
}
```

Then regenerate the lockfile:

```bash
cd modules/home/cli/pi-mono/extensions
pnpm install
```

### 5. Update Extensions Nix Hash

The extensions package is in `modules/home/cli/pi-mono/nix/extensions.nix`.

To get the new pnpm deps hash, set an invalid hash and build:

```bash
# Temporarily set invalid hash in extensions.nix
hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

# Build to get correct hash from error
nix build .#nixosConfigurations.<host>.config.system.build.toplevel 2>&1 | grep "got:"
```

Update the `hash` in `pnpmDeps` with the correct value.

### 6. Verify Build

```bash
# NixOS
nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# Verify version in output
nix-store -qR result | grep pi-mono-coding-agent
```

### 7. Apply

```bash
# NixOS
sudo nixos-rebuild switch --flake .#

# Darwin
nix run nix-darwin -- switch --flake .#
```

## Files to Update

| File | What to Update |
|------|----------------|
| `flake.lock` | `nix flake update pi-mono` |
| `modules/home/cli/pi-mono/nix/package.nix` | `npmDepsHash` |
| `modules/home/cli/pi-mono/extensions/package.json` | `@mariozechner/*` versions |
| `modules/home/cli/pi-mono/extensions/pnpm-lock.yaml` | `pnpm install` |
| `modules/home/cli/pi-mono/nix/extensions.nix` | `hash` in `pnpmDeps` |

## Common Errors

### Version Mismatch

```
ERROR: pi-mono version mismatch (input: X.Y.Z, declared: A.B.C)
```

**Cause:** Extensions `package.json` version doesn't match the flake input.

**Fix:** Update `@mariozechner/*` devDependencies in `extensions/package.json` to match the input version, then run `pnpm install`.

### Hash Mismatch

```
hash mismatch in fixed-output derivation
  specified: sha256-...
  got:       sha256-...
```

**Fix:** Use the hash from the `got:` line to update the relevant file.

### Chroot/Build Errors

```
error: getting status of '...drv.chroot/root/nix/store/...': No such file or directory
```

**Fix:** Try garbage collecting and rebuilding:
```bash
nix-collect-garbage -d
nix build ...
```

## Hash Calculation Reference

### npm deps hash (package.nix)

```bash
# 1. Build the prefetch tool
PREFETCH=$(nix-build '<nixpkgs>' -A prefetch-npm-deps --no-out-link)

# 2. Find source path (look for it in store or from derivation)
# After flake update, find the new source:
ls /nix/store/*-source/package-lock.json 2>/dev/null | xargs -I{} dirname {} | while read src; do
  if grep -q "pi-mono" "$src/package.json" 2>/dev/null; then echo "$src"; break; fi
done

# 3. Calculate hash
$PREFETCH/bin/prefetch-npm-deps <source-path>/package-lock.json
```

### pnpm deps hash (extensions.nix)

Use the invalid hash trick:
1. Set `hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";`
2. Run build
3. Copy the `got:` hash from the error

## Checking Release Notes

```bash
# Latest release info
curl -s "https://api.github.com/repos/badlogic/pi-mono/releases/latest" | jq -r '.tag_name, .name, .body'

# Compare versions
curl -s "https://api.github.com/repos/badlogic/pi-mono/compare/v0.49.3...v0.50.1" | jq -r '.commits[].commit.message' | head -20
```
