---
name: pi-mono-upgrade
description: "Upgrade pi-mono coding agent in NixOS/nix-darwin dotfiles. Updates flake input, package hashes, extension dependencies, and applies breaking changes to local extensions. Mechanical task - use Sonnet."
model: anthropic/claude-sonnet-4-5
---

# Pi-mono Upgrade Skill

Upgrade the pi-mono coding agent package in a Nix-based dotfiles repository.

## Upgrade Workflow

### 1. Check If Upgrade Needed

```bash
# Current vs latest - run both in parallel
pi --version
curl -s "https://api.github.com/repos/badlogic/pi-mono/tags?per_page=1" | jq -r '.[0].name'
```

If already on latest, **stop here** - no upgrade needed.

### 2. Check Breaking Changes

Only fetch the relevant portion of CHANGELOG between current and target versions:

```bash
CURRENT=$(pi --version)
curl -s "https://raw.githubusercontent.com/badlogic/pi-mono/main/packages/coding-agent/CHANGELOG.md" | \
  sed -n "/## \[${TARGET#v}/,/## \[${CURRENT}/p"
```

Look for `### Breaking Changes` sections. If none exist between versions, skip step 3.

### 3. Apply Breaking Changes to Local Extensions (if any)

Extensions are in `modules/home/cli/pi-mono/extensions/`.

See [Known Breaking Changes Reference](#known-breaking-changes-reference) below for specific migration patterns.

### 4. Update Flake Input

```bash
nix flake update pi-mono
```

### 5. Update Extensions package.json

Check if versions need updating:

```bash
# Check current declared version
grep "@mariozechner/pi-coding-agent" modules/home/cli/pi-mono/extensions/package.json
```

If version differs from target, update `package.json` and regenerate lockfile:

```bash
cd modules/home/cli/pi-mono/extensions
# Edit package.json to update @mariozechner/* versions
pnpm install
```

### 6. Test Build (Determines If Hashes Need Updating)

**Always build individual packages, never toplevel:**

```bash
nix build .#pi-mono-coding-agent 2>&1 | tail -20
```

**If build succeeds:** Hashes are already correct. Skip to step 8.

**If hash mismatch error:** Continue to step 7.

**If chroot/store error:** Run `nix-collect-garbage -d` and retry.

### 7. Update Hashes (Only If Step 6 Failed)

Set invalid hash in `modules/home/cli/pi-mono/nix/package.nix`:

```nix
npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
```

Build and capture correct hash:

```bash
nix build .#pi-mono-coding-agent 2>&1 | grep "got:"
```

Update `package.nix` with the hash from `got:` line.

Repeat for extensions if needed:

```bash
# Set invalid hash in extensions.nix, then:
nix build .#pi-mono-extensions 2>&1 | grep "got:"
```

### 8. Apply and Verify

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
| `modules/home/cli/pi-mono/extensions/*.ts` | Breaking API changes (if any) |
| `modules/home/cli/pi-mono/extensions/package.json` | `@mariozechner/*` versions |
| `modules/home/cli/pi-mono/extensions/pnpm-lock.yaml` | `pnpm install` |
| `modules/home/cli/pi-mono/nix/package.nix` | `npmDepsHash` (if build fails) |
| `modules/home/cli/pi-mono/nix/extensions.nix` | `hash` in `pnpmDeps` (if build fails) |

## Known Breaking Changes Reference

### v0.51.0 - Tool Execute Signature

Parameter order changed from `(id, params, onUpdate, ctx, signal)` to `(id, params, signal, onUpdate, ctx)`.

**Find affected code:**
```bash
rg "execute\(.*onUpdate.*ctx.*signal" modules/home/cli/pi-mono/extensions/
```

**Fix:** Swap `signal` and `onUpdate` parameters:

```typescript
// Before
async execute(_toolCallId, params, _onUpdate, ctx, signal) {

// After  
async execute(_toolCallId, params, signal, _onUpdate, ctx) {
```

### v0.51.3 - SlashCommandSource Type

RPC `get_commands` response renamed `"template"` to `"prompt"`.

## Common Errors

### Version Mismatch

```
ERROR: pi-mono version mismatch (input: X.Y.Z, declared: A.B.C)
```

**Fix:** Update `@mariozechner/*` in `extensions/package.json` to match input version, run `pnpm install`.

### Hash Mismatch

```
hash mismatch in fixed-output derivation
  specified: sha256-...
  got:       sha256-...
```

**Fix:** Copy hash from `got:` line to the relevant file.

### Chroot/Store Error

```
error: getting status of '...drv.chroot/root/nix/store/...': No such file or directory
```

**Fix:** 
```bash
nix-collect-garbage -d
# Then retry the build
```

### Tool Fails with "no-ui"

**Cause:** Tool execute signature not updated after v0.51.0 breaking change.

**Fix:** Update execute signature (see v0.51.0 above).
