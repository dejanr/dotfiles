---
name: pi-mono-upgrade
description: "Upgrade pi-mono coding agent in NixOS/nix-darwin dotfiles. Updates flake input, release-source and dependency hashes, extension dependencies, and applies breaking changes to local extensions. Mechanical task - use Sonnet."
model: anthropic/claude-sonnet-4-5
---

# Pi-mono Upgrade Skill

Upgrade the repository's Nix packages, verify them, then ask before activation. Do not commit unless requested.

## 1. Preflight

Run from the repository root. Record these versions separately; carry recorded values into later commands rather than assuming shell variables persist between tool calls.

```bash
git status --short
pi --version
nix eval --raw .#pi-mono-coding-agent.version
curl -fsSL 'https://api.github.com/repos/earendil-works/pi/releases/latest' | jq -r '.tag_name'
(cd modules/home/cli/pi-mono/extensions && pnpm config get minimum-release-age)
```

- **Installed version:** `pi --version`; may lag an already-updated repository.
- **Repository version:** the evaluated package version; use this as the changelog baseline.
- **Target version:** latest stable release, unless the user requests another version.

If repository and installed versions already match the target, stop. If only the repository matches, verify its package/dependency consistency and builds, then offer activation rather than repeating the bump. Preserve existing user changes.

Read `nix/package.nix`, `nix/extensions.nix`, and `extensions/package.json` under `modules/home/cli/pi-mono/`, plus the extensions README. Check both root devDependencies and overrides, and relevant Home Manager integration when packaging changes.

The repository configures a seven-day pnpm release-age policy. Check whether the target is old enough before installing. If it is blocked, **ask before making an exception**; do not silently disable the policy. With explicit approval, a one-command exception is:

```bash
(cd modules/home/cli/pi-mono/extensions && pnpm install --config.minimum-release-age=0)
```

This bypasses the age check for the entire invocation, including transitive dependencies; it does not change the persistent policy.

## 2. Review Compatibility and Update Versions

Fetch `packages/coding-agent/CHANGELOG.md` from the **target release tag**, not `main`. Inspect only the range from the repository version to the target. Check API removals and changed behavior as well as headings labeled breaking changes. Search local extension usage before deciding migration is unnecessary.

For affected integrations, read the relevant Pi API docs and examples before editing. Avoid unrelated documentation and extension refactors.

```bash
nix flake update pi-mono
nix eval --raw .#pi-mono-coding-agent.version
```

The input tracks the default branch, not the release tag. Confirm its resulting package version matches the chosen target; reconcile any mismatch before proceeding.

Update all root `@earendil-works/*` version pins in `extensions/package.json`, including **devDependencies and pnpm overrides**. Keep extension peer dependencies as `"*"`; do not introduce per-extension version pins.

```bash
(cd modules/home/cli/pi-mono/extensions && pnpm install)
```

Every workspace command must explicitly select the extensions directory. Use the approved age exception instead of the normal install only when needed.

## 3. Refresh All Changed Hashes Before Verification Builds

There are **three** independent fixed-output hashes:

| File under `modules/home/cli/pi-mono/` | Hash | Refresh when |
|---|---|---|
| `nix/package.nix` | `releaseSource.hash` | Release archive changes |
| `nix/package.nix` | `npmDepsHash` | Release dependency lockfile changes |
| `nix/extensions.nix` | `pnpmDeps.hash` | Extension dependency lockfile changes |

**A successful build with an old source hash does not prove an upgrade.** Nix can reuse the cached old archive even when the URL and derivation version change.

Prefetch the new archive first (set `TARGET` to the recorded tag, including `v`):

```bash
nix store prefetch-file --unpack --json \
  "https://github.com/earendil-works/pi/releases/download/${TARGET}/pi-${TARGET#v}-source.tar.gz"
```

Copy the returned `hash` into `releaseSource.hash`. This unpacked hash matches the current `fetchzip` configuration. Inspect the returned store path's `packages/coding-agent/package.json` to confirm its version matches the target. If archive layout or fetch options change, obtain the hash through the actual fetchzip derivation instead.

For a normal release bump, invalidate `npmDepsHash` upfront unless the release dependency lockfile is known to be unchanged:

```nix
npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
```

If the extension dependency lockfile changed, set `pnpmDeps.hash` in `extensions.nix` to `""`.

Collect dependency hashes in **one Nix invocation**, using `--keep-going` so independent fetches can both report mismatches:

```bash
nix build .#pi-mono-coding-agent .#pi-mono-extensions --no-link --keep-going
```

Match each `got: sha256-...` to its failing derivation and update the corresponding hash. These mismatches are expected discovery steps, not verification failures. Do not repeatedly try unchanged stale hashes first.

## 4. Build and Verify

**Build individual packages, never the system toplevel.** Use one Nix invocation rather than concurrent Nix processes that can contend for the evaluation cache. Run long commands directly with live output when available; do not pipe them through `tail`, `grep`, or similar filters.

```bash
nix build .#pi-mono-coding-agent .#pi-mono-extensions --no-link --print-out-paths
```

Identify the printed coding-agent output path, then verify that exact artifact—not the still-installed `pi`:

```bash
PI_BUILD='<printed-coding-agent-path>'
"$PI_BUILD/bin/pi" --version
node --input-type=module -e '
  const pi = await import(process.argv[1]);
  if (typeof pi.createAgentSession !== "function") throw new Error("Missing SDK export");
  console.log("SDK import OK");
' "$PI_BUILD/lib/pi-mono/packages/coding-agent/dist/index.js"
```

Run extension diagnostics independently of build success; they can run in parallel with the Nix build:

```bash
(cd modules/home/cli/pi-mono/extensions && pnpm run typecheck)
(cd modules/home/cli/pi-mono/extensions && pnpm run lint)
```

Investigate failures enough to distinguish upgrade regressions from unrelated configuration/vendor issues. Report the latter without expanding upgrade scope. A lint rerun excluding an unrelated vendor directory is supplemental, not a full lint pass.

## 5. Review and Offer Activation

```bash
git diff --check
git diff --stat
git status --short
```

Expected upgrade files:

- `flake.lock`
- `modules/home/cli/pi-mono/extensions/package.json`
- `modules/home/cli/pi-mono/extensions/pnpm-lock.yaml`
- `modules/home/cli/pi-mono/nix/package.nix`
- `modules/home/cli/pi-mono/nix/extensions.nix`

Review handwritten changes and dependency changes selectively; avoid dumping the entire lockfile diff by default. Ensure no placeholder hashes remain. Summarize build, runtime, and diagnostic results separately.

**Ask for user confirmation before running a system switch.** After approval, use the appropriate command:

```bash
sudo nixos-rebuild switch --flake .#
```

```bash
nix run nix-darwin -- switch --flake .#
```

After activation, run `pi --version` again. Do not imply the running session was upgraded merely because the new package built.

## Recovery Notes

- **Version mismatch:** Align the input version and root dependency/override pins, then regenerate the extension lockfile.
- **Outdated `npmDepsHash`:** Invalidate it and collect the `got:` hash as above.
- **`ERR_PNPM_NO_OFFLINE_TARBALL`:** Refresh `pnpmDeps.hash` with `""`, collect its hash, and rebuild.
- **Stale workspace types:** Check resolved versions, then try `(cd modules/home/cli/pi-mono/extensions && pnpm install --force)`, respecting the release-age policy. Keep version pins centralized; do not start with destructive cleanup.
- **Chroot/store errors:** Inspect the failing derivation and logs, then retry if transient. Do not automatically run `nix-collect-garbage -d`: it deletes old generations. Ask before destructive store maintenance.

## Historical API Migrations

Consult only when crossing these versions:

- **0.51.0:** Tool execute parameters changed from `(id, params, onUpdate, ctx, signal)` to `(id, params, signal, onUpdate, ctx)`. Incorrect ordering can make UI tools report `no-ui` or resolve `ctx` as an `AbortSignal`.
- **0.51.3:** RPC `get_commands` source changed from `"template"` to `"prompt"`.
