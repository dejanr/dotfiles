---
name: pi-mono-upgrade
description: "Upgrade pi-mono coding agent in NixOS/nix-darwin dotfiles. Updates flake input, package hashes, extension dependencies, and applies breaking changes to local extensions. Mechanical task - use Sonnet."
model: anthropic/claude-sonnet-4-5
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

# Build pi-mono packages directly
nix build .#pi-mono-coding-agent
nix build .#pi-mono-extensions
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

### 2. Check Breaking Changes (CRITICAL)

**Before upgrading, always check for breaking changes that affect local extensions.**

```bash
# Get current and target versions
CURRENT=$(pi --version)
TARGET=$(curl -s "https://api.github.com/repos/badlogic/pi-mono/tags?per_page=1" | jq -r '.[0].name')

# Fetch CHANGELOG and check for breaking changes between versions
curl -s "https://raw.githubusercontent.com/badlogic/pi-mono/main/packages/coding-agent/CHANGELOG.md" | \
  sed -n "/## \[$TARGET/,/## \[$CURRENT/p" | grep -A5 -i "breaking"
```

Alternatively, if you have `~/projects/pi-mono` checked out:

```bash
cat ~/projects/pi-mono/packages/coding-agent/CHANGELOG.md | head -300
```

Look for sections marked:
- `### Breaking Changes`
- `BREAKING CHANGE:` in commit messages
- Changes to `ToolDefinition`, `ExtensionAPI`, `ExtensionContext`, or `ctx.ui.*`

### 3. Apply Breaking Changes to Local Extensions

Local extensions are in `modules/home/cli/pi-mono/extensions/`.

**Common breaking change patterns:**

#### Tool Execute Signature Change (v0.51.0)

If upgrading across v0.51.0, tool execute signatures changed:

```typescript
// Old signature (pre-0.51.0)
async execute(toolCallId, params, onUpdate, ctx, signal) { ... }

// New signature (0.51.0+)
async execute(toolCallId, params, signal, onUpdate, ctx) { ... }
```

Find and update all affected tools:

```bash
# Find old signature pattern
rg "async execute\(_?toolCallId.*params.*onUpdate.*ctx.*signal" modules/home/cli/pi-mono/extensions/

# Or broader search for execute functions
rg "async execute\(" modules/home/cli/pi-mono/extensions/ --type ts
```

Update each match by swapping `signal` and `onUpdate` parameters.

#### Other API Changes

Check for usage of changed APIs in your extensions:

```bash
# Search for potentially affected patterns
rg "ctx\.hasUI|ctx\.ui\.|pi\.registerTool|ToolDefinition" modules/home/cli/pi-mono/extensions/ --type ts
```

Compare your usage against the updated docs:
- `~/projects/pi-mono/packages/coding-agent/docs/extensions.md`
- `~/projects/pi-mono/packages/coding-agent/src/core/extensions/types.ts`

### 4. Update Flake Input

```bash
nix flake update pi-mono
```

This updates `flake.lock` with the new revision.

### 5. Update Extensions package.json

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

### 6. Update Both Nix Hashes (Invalid Hash Trick)

Both `package.nix` and `extensions.nix` need hash updates. The simplest approach is to use invalid hashes and let the build tell you the correct ones.

**Step 6a: Set invalid hashes in both files:**

In `modules/home/cli/pi-mono/nix/package.nix`:

```nix
npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
```

In `modules/home/cli/pi-mono/nix/extensions.nix`:

```nix
hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
```

**Step 6b: Build packages and capture correct hashes:**

Build the main pi-mono package first:

```bash
nix build .#pi-mono-coding-agent 2>&1 | tail -50
```

The build will fail with a hash mismatch:

```
error: hash mismatch in fixed-output derivation '...-pi-mono-coding-agent-...-npm-deps.drv':
         specified: sha256-AAA...
            got:    sha256-Q68ag/zfR1xF4g48r/e0C7i2YuCR6sGQqdeDMyr7nCM=
```

Update `package.nix` with the hash from the `got:` line, then build extensions:

```bash
nix build .#pi-mono-extensions 2>&1 | tail -50
```

You'll get the extensions hash mismatch:

```
error: hash mismatch in fixed-output derivation '...-pi-mono-extensions-pnpm-deps.drv':
         specified: sha256-AAA...
            got:    sha256-P+2ldIgK6I6WgVPEOrWIgxwH8sIiPmP7ASrFqPZ0vhY=
```

Update `extensions.nix` with that hash.

### 7. Verify Build

```bash
# Verify both packages build successfully
nix build .#pi-mono-coding-agent --no-link
nix build .#pi-mono-extensions --no-link
```

### 8. Apply

```bash
# NixOS
sudo nixos-rebuild switch --flake .#

# Darwin
nix run nix-darwin -- switch --flake .#

# Verify
pi --version
```

### 9. Test Extensions

After applying, verify your extensions work correctly:

```bash
# Test tool registration (should not error on startup)
pi --help

# If you have a debug_context tool, test it
# In pi: "Call debug_context tool"

# Test any tools that use ctx.hasUI or interactive features
# In pi: "Use git_commit_with_user_approval with message 'test: verify upgrade'"
```

If tools fail with `no-ui` or similar context errors, the execute signature likely wasn't updated correctly.

## Files to Update

| File                                                 | What to Update                          |
| ---------------------------------------------------- | --------------------------------------- |
| `flake.lock`                                         | `nix flake update pi-mono`              |
| `modules/home/cli/pi-mono/extensions/*.ts`           | Breaking API changes (signatures, etc.) |
| `modules/home/cli/pi-mono/extensions/package.json`   | `@mariozechner/*` versions              |
| `modules/home/cli/pi-mono/extensions/pnpm-lock.yaml` | `pnpm install`                          |
| `modules/home/cli/pi-mono/nix/extensions.nix`        | `hash` in `pnpmDeps`                    |
| `modules/home/cli/pi-mono/nix/package.nix`           | `npmDepsHash`                           |

## Known Breaking Changes Reference

### v0.51.0 - Tool Execute Signature

Parameter order changed from `(id, params, onUpdate, ctx, signal)` to `(id, params, signal, onUpdate, ctx)`.

**Symptom:** Tools fail with `no-ui` error even in interactive mode, or `ctx` is undefined/wrong type.

**Fix:** Swap `signal` and `onUpdate` parameters in all `execute()` functions:

```typescript
// Before
async execute(_toolCallId, params, _onUpdate, ctx, signal) {

// After  
async execute(_toolCallId, params, signal, _onUpdate, ctx) {
```

**Find affected code:**
```bash
rg "execute\(.*onUpdate.*ctx.*signal" modules/home/cli/pi-mono/extensions/
```

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

**Fix:** Use the hash from the `got:` line to update the relevant file (`package.nix` for npm-deps, `extensions.nix` for pnpm-deps).

### Tool Fails with "no-ui"

```
Failed: no-ui
```

**Cause:** Tool execute signature not updated after breaking change. The `ctx` parameter is receiving the wrong value.

**Fix:** Check and update execute signature (see v0.51.0 breaking change above).

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

# Full CHANGELOG
curl -s "https://raw.githubusercontent.com/badlogic/pi-mono/main/packages/coding-agent/CHANGELOG.md" | head -200
```

## Debugging Extension Issues Post-Upgrade

If extensions misbehave after upgrade:

1. **Check pi-mono source** (if available):
   ```bash
   cat ~/projects/pi-mono/packages/coding-agent/src/core/extensions/types.ts
   ```

2. **Compare with example extensions**:
   ```bash
   ls ~/projects/pi-mono/packages/coding-agent/examples/extensions/
   cat ~/projects/pi-mono/packages/coding-agent/examples/extensions/hello.ts
   ```

3. **Use git bisect** to find breaking commit (if you have source):
   ```bash
   cd ~/projects/pi-mono
   git bisect start
   git bisect bad HEAD
   git bisect good v0.50.0  # last known working version
   # Test each commit with: tsx packages/coding-agent/src/cli.ts
   ```

4. **Add debug tool** to inspect context:
   ```typescript
   pi.registerTool({
     name: "debug_context",
     parameters: Type.Object({}),
     async execute(_id, _params, _signal, _onUpdate, ctx) {
       return {
         content: [{ type: "text", text: JSON.stringify({
           hasUI: ctx.hasUI,
           uiKeys: Object.keys(ctx.ui),
           cwd: ctx.cwd,
         }, null, 2) }],
       };
     },
   });
   ```
