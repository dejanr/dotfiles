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

Do **not** use destructive cleanup (`rm -rf`) as a default recovery step. If dependency resolution appears stale, prefer `pnpm install --force`.

### 6. Test Builds (Determines If Hashes Need Updating)

**Always build individual packages, never toplevel:**

```bash
nix build .#pi-mono-coding-agent 2>&1 | tail -20
nix build .#pi-mono-extensions 2>&1 | tail -30
```

Interpret results:

- **Both builds succeed:** hashes are correct, continue to step 8.
- **Hash mismatch (`specified` vs `got`)**: continue to step 7 for the failing derivation.
- **`ERR_PNPM_NO_OFFLINE_TARBALL` (extensions build):** continue to step 7 (extensions hash refresh flow).
- **Chroot/store error:** run `nix-collect-garbage -d` and retry.

### 7. Update Hashes (Only for Failing Derivation)

#### Coding agent hash (`package.nix`)

Set invalid hash in `modules/home/cli/pi-mono/nix/package.nix`:

```nix
npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
```

Build and capture correct hash:

```bash
nix build .#pi-mono-coding-agent 2>&1 | grep "got:"
```

Update `package.nix` with the hash from the `got:` line.

#### Extensions hash (`extensions.nix`)

For extensions, set empty hash in `modules/home/cli/pi-mono/nix/extensions.nix`:

```nix
hash = "";
```

Then build and capture the `got:` hash:

```bash
nix build .#pi-mono-extensions 2>&1 | grep "got:"
```

Update `extensions.nix` with the captured hash.

### 8. Sanity-check Changed Files

```bash
git status --short
```

Expected changed files for a normal upgrade:

- `flake.lock`
- `modules/home/cli/pi-mono/extensions/package.json`
- `modules/home/cli/pi-mono/extensions/pnpm-lock.yaml`
- `modules/home/cli/pi-mono/nix/package.nix`
- `modules/home/cli/pi-mono/nix/extensions.nix`

### 9. Apply and Verify

**Ask for user confirmation before running system switch commands.**

```bash
# NixOS
sudo nixos-rebuild switch --flake .#

# Darwin
nix run nix-darwin -- switch --flake .#

# Verify
pi --version
```

Optional diagnostic (non-blocking for the version bump itself):

```bash
cd modules/home/cli/pi-mono/extensions
pnpm run typecheck
# If types look stale after version bumps, refresh resolution without deleting folders:
pnpm install --force
# Optionally pin all workspace resolutions explicitly:
pnpm up -r @mariozechner/pi-ai@<target-version> @mariozechner/pi-coding-agent@<target-version> @mariozechner/pi-tui@<target-version>
# pnpm run lint may fail due to local parser/config differences; treat as follow-up work
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

### ERR_PNPM_NO_OFFLINE_TARBALL

```
ERR_PNPM_NO_OFFLINE_TARBALL
A package is missing from the store but cannot download it in offline mode.
```

**Fix (extensions):**

1. Set `pnpmDeps.hash = "";` in `modules/home/cli/pi-mono/nix/extensions.nix`
2. Run `nix build .#pi-mono-extensions 2>&1 | grep "got:"`
3. Copy the `got: sha256-...` value back to `pnpmDeps.hash`

### Stale Workspace Type Resolution

Symptoms (after dependency bump):

```
Property 'hasUI' does not exist on type 'AbortSignal'
Type 'AgentToolUpdateCallback<...>' is not assignable to type 'AbortSignal'
```

**Cause:** workspace packages are still resolving older `@mariozechner/*` types.

**Fix:**

```bash
cd modules/home/cli/pi-mono/extensions
pnpm install --force
# If still stale, force workspace package versions:
pnpm up -r @mariozechner/pi-ai@<target-version> @mariozechner/pi-coding-agent@<target-version> @mariozechner/pi-tui@<target-version>
pnpm run typecheck
```

Do not use `rm -rf` as the first recovery step.

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
