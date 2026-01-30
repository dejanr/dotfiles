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

# Get current hostname for build commands
hostname

# Update flake input
nix flake update pi-mono
```

## Upgrade Workflow

### 1. Check Versions

```bash
# Current version
pi --version

# Latest available
curl -s "https://api.github.com/repos/badlogic/pi-mono/tags?per_page=5" | jq -r '.[].name'
```

If already on latest, no upgrade needed.

### 2. Update Flake Input

```bash
nix flake update pi-mono
```

This updates `flake.lock` with the new revision.

### 3. Update Extensions package.json

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

### 4. Update Both Nix Hashes (Invalid Hash Trick)

Both `package.nix` and `extensions.nix` need hash updates. The simplest approach is to use invalid hashes and let the build tell you the correct ones.

**Step 4a: Set invalid hashes in both files:**

In `modules/home/cli/pi-mono/nix/package.nix`:
```nix
npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
```

In `modules/home/cli/pi-mono/nix/extensions.nix`:
```nix
hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
```

**Step 4b: Build and capture correct hashes:**

```bash
# IMPORTANT: Use actual hostname, not a placeholder
HOST=$(hostname)
nix build .#nixosConfigurations.$HOST.config.system.build.toplevel 2>&1 | tail -100
```

The build will fail with hash mismatches. Look for lines like:
```
error: hash mismatch in fixed-output derivation '...-pi-mono-extensions-pnpm-deps.drv':
         specified: sha256-AAA...
            got:    sha256-P+2ldIgK6I6WgVPEOrWIgxwH8sIiPmP7ASrFqPZ0vhY=
```

Update `extensions.nix` with the hash from the `got:` line, then build again:

```bash
nix build .#nixosConfigurations.$HOST.config.system.build.toplevel 2>&1 | tail -100
```

Now you'll get the `package.nix` hash mismatch:
```
error: hash mismatch in fixed-output derivation '...-pi-mono-coding-agent-...-npm-deps.drv':
         specified: sha256-AAA...
            got:    sha256-Q68ag/zfR1xF4g48r/e0C7i2YuCR6sGQqdeDMyr7nCM=
```

Update `package.nix` with that hash.

### 5. Verify Build

```bash
HOST=$(hostname)
nix build .#nixosConfigurations.$HOST.config.system.build.toplevel

# Verify version in output
nix-store -qR result | grep pi-mono-coding-agent
```

### 6. Apply

```bash
# NixOS
sudo nixos-rebuild switch --flake .#

# Darwin
nix run nix-darwin -- switch --flake .#

# Verify
pi --version
```

## Files to Update

| File | What to Update |
|------|----------------|
| `flake.lock` | `nix flake update pi-mono` |
| `modules/home/cli/pi-mono/extensions/package.json` | `@mariozechner/*` versions |
| `modules/home/cli/pi-mono/extensions/pnpm-lock.yaml` | `pnpm install` |
| `modules/home/cli/pi-mono/nix/extensions.nix` | `hash` in `pnpmDeps` |
| `modules/home/cli/pi-mono/nix/package.nix` | `npmDepsHash` |

## Common Errors

### Host Not Found

```
error: flake '...' does not provide attribute '...nixosConfigurations.dex...'
```

**Cause:** Using wrong hostname. The build target must match an existing host configuration.

**Fix:** Use `hostname` to get current host, or check available hosts:
```bash
nix eval .#nixosConfigurations --apply builtins.attrNames
```

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

**Fix:** Use the hash from the `got:` line to update the relevant file (`package.nix` for npm-deps, `extensions.nix` for pnpm-deps).

### Chroot/Build Errors

```
error: getting status of '...drv.chroot/root/nix/store/...': No such file or directory
```

**Fix:** Try garbage collecting and rebuilding:
```bash
nix-collect-garbage -d
nix build ...
```

## Checking Release Notes

```bash
# Latest release info
curl -s "https://api.github.com/repos/badlogic/pi-mono/releases/latest" | jq -r '.tag_name, .name, .body'

# Compare versions
curl -s "https://api.github.com/repos/badlogic/pi-mono/compare/v0.49.3...v0.50.1" | jq -r '.commits[].commit.message' | head -20
```
