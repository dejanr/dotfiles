# HorizonXI frame-time investigation

## Scope

The reported symptom is visual freezes/FPS drops. No frame-time baseline has been captured and no fix has been verified. ProtonDB reports concern retail FFXI, not necessarily HorizonXI's launcher and Ashita build.

## Local observations

- `hosts/omega/home.nix` launches HorizonXI through GE-Proton/umu and GameMode, with `PROTON_DXVK_D3D8=0`.
- Inspection of the running `horizon-loader` process found Wine's built-in `d3d8.dll` and `wined3d.dll` loaded. GameMode was active; the CPU governor was `performance`. A single GPU sample was 11% busy, which cannot rule out transient GPU bottlenecks.
- `hosts/omega/horizonxi/patch-launcher.cjs` preserves the selected gamepad device ID when importing controller configuration. Disabling controller support permanently would undermine that integration.
- The DXVK-disable setting is part of pre-existing uncommitted changes. Its rationale is unknown; do not silently remove it.

## Relevant reports and applicability

### 1. Gamepad support: first reversible comparison

A [firsthand ProtonDB report](https://www.protondb.com/app/230350) using GE-Proton10-25 on Fedora with an AMD RX 7800 XT says: “On install, experienced major stuttering. Found it was due to gamepad being enabled.”

Temporarily disable gamepad support in the game/launcher settings, restart, and compare the same scene. This is a diagnostic comparison, not a confirmed cause or a recommendation to abandon controller support. If it helps, investigate controller selection and connection while preserving the existing device-ID fix.

### 2. Graphics backend: separate comparison

The same report recommends disabling dgVoodoo2, enabling DXVK, and using atom0s's Direct3D proxy. The [proxy author's explanation](https://www.bluegartr.com/threads/129943-Direct3D8-to-Direct3D9-Proxy-Performance-Helper-(For-FFXI)) confirms that it translates D3D8 calls into D3D9 and was primarily designed to address switchable-GPU problems on Windows laptops. This does not prove an improvement on this Linux desktop.

The simpler local experiment is GE-Proton's bundled DXVK D3D8 support, rather than immediately installing another DLL. Confirm why it was disabled, then compare it against the current WineD3D path with all other settings unchanged. Verify the loaded renderer and Ashita compatibility after restarting; revert on rendering or startup regressions.

If the bundled path is incompatible, atom0s's proxy plus DXVK D3D9 is a separate candidate. Retail PlayOnline installation instructions should not be copied blindly to HorizonXI's bootloader layout.

### 3. Do not copy the complete launch-option recipe

The ProtonDB report also lists ESync off, FSync on, `DXVK_CONFIG="dxgi.syncInterval=0"`, and DLL overrides. The report changes multiple variables, so it does not establish which improved performance.

[DXVK's configuration reference](https://github.com/doitsujin/dxvk/blob/8f8a93696d36adca8efeed4e16dc6b3deea27268/dxvk.conf) distinguishes `dxgi.syncInterval` from `d3d9.presentInterval`. The latter is the relevant VSync override for a D3D9 proxy path; DXVK settings do not tune the current WineD3D renderer. Disabling VSync may introduce tearing and is not a verified stutter fix here.

Old Proton 4.x/7.x recommendations on the page primarily address installation/launch compatibility. They are not evidence that downgrading this working GE-Proton setup will improve frame times.

## Recommended order

Capture a repeatable scene, compare gamepad enabled/disabled, restore it, then compare renderers if necessary. Change one variable at a time and judge frame-time spikes rather than average FPS.

## atom0s proxy trial

At the user's request, installed the supplied `~/downloads/ffxi_d3d8to9_proxy_v1.1.0.0-by_atom0s.zip`:

- Archive SHA256: `155feeb0b058a7530059800b7f342f1bb1abcf90f6bee296c28ab84cd1426f5f` (local fingerprint, not independently authenticated).
- Copied `d3d8.dll` and `d3d8.ini` to `~/games/ffxi/HorizonXI/Game/bootloader/`, beside `horizon-loader.exe`, following the archive's private-server installation instructions. Neither destination existed beforehand.
- Retained the shipped INI: proxy enabled; force-flush and all optional overrides disabled.
- Confirmed that the prefix's 32-bit `d3d9.dll` is byte-identical to GE-Proton10-34's bundled DXVK library. The proxy's required `d3dx9_43.dll`, `msvcp140.dll`, and `vcruntime140.dll` exist; successful runtime loading still needs verification.
- Backed up prefix registry files, game configuration/scripts, and original proxy files under `~/games/horizonxi/tools/before-atom0s-proxy-20260909-114015/` (private directory).

Started the existing installed HorizonXI launcher with these one-off environment overrides:

```sh
WINEDLLOVERRIDES='*d3d8=n;d3d9=n'
DXVK_HUD='fps,frametimes,compiler'
DXVK_LOG_LEVEL=info
DXVK_LOG_PATH="$HOME/.local/state/horizonxi/atom0s-test"
```

Inherited `PROTON_USE_WINED3D`, `DXVK_CONFIG`, and `DXVK_CONFIG_FILE` were unset for the trial. The existing launcher retains `PROTON_DXVK_D3D8=0`: atom0s supplies D3D8, while DXVK supplies D3D9. No synchronization or controller settings were changed, and no persistent Nix launcher changes were made for this trial.

After game login, `/proc/185842/maps` confirmed that `horizon-loader.exe` loaded the local `bootloader/d3d8.dll` and the prefix's DXVK `d3d9.dll`. The game's `horizon-loader_d3d9.log` confirms DXVK `v2.7.1-509-g1676dcaf342a9b1`, using the RX 9070 XT through RADV 26.1.0, not llvmpipe. Presentation is windowed at 3840×2160 with FIFO VSync. WineD3D also remains mapped; that alone does not negate the confirmed active DXVK D3D9 device.

A 30-second sample (one-second intervals) is saved in `~/.local/state/horizonxi/atom0s-test/system-sample.csv`:

| Metric | Mean | Range |
| --- | --- | --- |
| Game CPU (one logical CPU = 100%) | 25.9% | 23.9–29.8% |
| Busiest game thread | 15.6% | 13.9–17.9% |
| Whole-GPU utilization | 13.7% | 8–17% |
| GPU edge temperature | 28.2°C | 28–29°C |
| GPU junction temperature | 34.5°C | 33–35°C |
| Whole-GPU VRAM usage | ~3.1 GiB | ~3.1 GiB |

GameMode and the performance CPU governor remain active. No error entries appeared in the inspected game DXVK log; it contains one unhandled render-state-47 warning. These samples show substantial average hardware headroom, but cannot detect or rule out individual long frames. There is no matched WineD3D baseline, so a numerical improvement cannot be claimed. Attempted HUD-only window capture was unavailable (X11 image access failed); no measured FPS/percentile frame-time result is available yet. User confirmation of stutter behavior or a dedicated frame-time capture remains necessary.

The user reported that gameplay feels much better with the proxy. This is a subjective improvement, not a measured frame-time benchmark.

## Persistent launcher configuration

`hosts/omega/home.nix` now selects atom0s + DXVK D3D9 when both `bootloader/d3d8.dll` and `bootloader/d3d8.ini` exist. It retains `PROTON_DXVK_D3D8=0`, sets `PROTON_USE_WINED3D=0`, and clears `DXVK_HUD` so normal launches do not show the diagnostic overlay. If either proxy file is absent, it explicitly selects Wine's built-in D3D8 as the fallback. The proxy files remain a local installation, not Nix-managed downloads.

Nix syntax/formatting checks and shell checks for installed, missing, and incomplete proxy configurations passed. Rebuild the host configuration and restart the launcher to apply; the already-running test session is unchanged.

For rollback, close the game and launcher, move the two newly installed `bootloader/d3d8.*` files out of the bootloader directory, and restart through the normal desktop entry without the trial environment. Registry/configuration backups are precautionary; do not restore them unless necessary, since that would discard subsequent settings changes.
