# Tooling

> Notes from reverse-engineering the Akai MPC Sample firmware and verifying the mods built on it.
> Companion documents (`EMULATOR.md`, `MECHANISMS.md`, `MODDING.md`, `HISTORY.md`,
> `ADDIN-ECOSYSTEM.md`) are not published; they are referenced by name only.

Every tool used to reverse-engineer the MPC Sample and to verify the mod, with
the exact invocation pattern that works. The method these tools serve is in
[`RE-METHOD.md`](RE-METHOD.md); the lab itself is described in
`EMULATOR.md`.

| tool | role | where |
|---|---|---|
| Ghidra 12.2 + MCP bridge | decompile, xrefs, RTTI, vtables | `tools/ghidra/hpss/` |
| Ghidra Java scripts | targeted dumps driven by the bridge | `tools/ghidra/hpss/*.java` |
| kuna, radare2 | quick decompile, sections, relocations, bytes | host |
| Python static helpers | vptr→class, BL call sites, string xrefs | `tools/re/` |
| emulator lab (`virtual-mpc-sample`) | run the stock firmware, click the panel | sibling checkout |
| panel + QMP | drive and screenshot the emulator | lab |
| in-process probes | observe the live app from inside | `mod` debug build |
| host harnesses | read the model, tap audio, watch writes | `mod/tests/`, `tools/` |
| device probes | ground truth from real hardware | `tools/device/` |

## 1. Ghidra and the MCP bridge

The binary is `/usr/bin/MPC Sample` (firmware 1.3.0.12), imported into Ghidra as
`mpcsample.bin` (`~/mcpsamplebin.gpr`). **Ghidra VA = mod offset + `0x100000`**;
the loader's image base is `0x100000`, and the mod uses file offsets.

The bridge is [GhidraMCP](https://github.com/bethington/ghidra-mcp). The released
`GhidraMCP-7.0.0.zip` is built for Ghidra 12.1.4 and fails against 12.2 with
`ghidra/program/model/lang/SleighLanguageDescription` on every decompile. Build
the 12.2 branch instead:

```sh
git clone https://github.com/bethington/ghidra-mcp
cd ghidra-mcp && git fetch --depth 1 origin chore/ghidra-12.2
git checkout -f FETCH_HEAD
./gradlew buildExtension -PGHIDRA_INSTALL_DIR=$HOME/Applications/ghidra_12.2_PUBLIC
# -> build/distributions/GhidraMCP-7.0.0.zip  (extension.properties: version=12.2)
EXT=$HOME/Library/ghidra/ghidra_12.2_PUBLIC/Extensions
rm -rf "$EXT/GhidraMCP" && unzip -q build/distributions/GhidraMCP-7.0.0.zip -d "$EXT"
```

Verified afterwards: 216 endpoints, `force_decompile` works, analysis survives a
restart (69,271 functions). The bridge is MCP-over-HTTP; it can also be spoken to
over stdio with `initialize → tools/list → tools/call`, which is enough for a
~30-line Python driver.

### Running the Java scripts

Copy `tools/ghidra/hpss/*.java` to `~/ghidra_scripts`, start Ghidra with
`GHIDRA_MCP_ALLOW_SCRIPTS=1`, open the project, then:

```sh
python3 tools/ghidra/hpss/run_bridge.py ResearchDecompile.java 0x17580d0 0x153ed40
python3 tools/ghidra/hpss/run_bridge.py DumpVtable.java 0x07180be0 36
python3 tools/ghidra/hpss/run_bridge.py FindConst.java 100 3000
```

`run_bridge.py` keeps one MCP session for init, connect and script execution. It
contains a workstation-specific bridge path and defaults to `knob.bin`.

| script | use |
|---|---|
| `ResearchDecompile` | decompile explicit addresses; creates a function at the address if Ghidra has none (`-noanalysis` workflow) |
| `DisasmRange` | raw instructions for a range |
| `DumpVtable` / `DumpRTTI` / `DumpWords` | vtable slots, RTTI names, raw words at an address |
| `DumpParams` / `DumpParamNames` | parameter tables (name, range, default) |
| `FindConst` / `FindStrings` / `FindPointerValues` | constants, string xrefs, pointers to a value |
| `FindFunctionRefs` / `FindIndirectSlot` / `FindOffsetUse` | callers and users of a slot/offset |
| `HpssEntry` | search backwards for `PACIASP` to get candidate function entries |
| `HpssInstructions` / `HpssCommandTrace` / `HpssRefs` / `HpssReadPointers` / `HpssFindExtract` | HPSS-specific traces of the Extract command |
| `ProgramInfo` | image base, blocks, function count |

Headless without the bridge (enough for one-off decompilation):

```sh
GHIDRA_HEADLESS_MAXMEM=32G analyzeHeadless /tmp/ghproj mpc \
  -import /tmp/mpcsample.bin -noanalysis \
  -scriptPath tools/ghidra -postScript DumpFuncs2.java
```

`-noanalysis` plus "disassemble window + `createFunction`" per target is enough
for exact decompilation and avoids a multi-hour auto-analysis of a 120 MB image.
Argument types in Ghidra's output are hints; the registers at a live call are
the contract.

### Static identifier helpers (`tools/re/`)

| tool | use |
|---|---|
| `classof.py` | live `vptr` → class name (typeinfo at `vptr−8`, name at `typeinfo+8`); `--scan dump.bin` names every vtable slot in a memory dump |
| `calls.py` | every `BL` call site to an address ("who calls this") |
| `fwxref.py` | `adrp/add/ldr` scan — every reference to a string or global |
| `rtti.py` | RTTI name → type_info → vtable |
| `arm_xrefs.py` | cross-references in a raw ARM image |

These need no disassembler: `.data.rel.ro` and `.rela.dyn` resolve vtables from
the file alone (464,288 `R_AARCH64_RELATIVE` relocations in this build).

### Quick decompilation outside Ghidra

* `kuna decompile <file> <addr> --addr` — per-function pseudocode, fast.
* `radare2` — sections, dynamic relocations, byte reads (`px`, `iS`, `ir`).
* `nm`/`objdump` on the mod's own unstripped `.elf` for mod-side symbols.

## 2. The emulator lab

The lab is the sibling checkout `~/projects/customs/virtual-mpc-sample`
(<https://github.com/orrpunk-art/virtual-mpc-sample>): stock firmware 1.3.0.12
in QEMU with the whole front panel as a web page. Details and setup:
`EMULATOR.md`.

```sh
python3 lab.py run        # boot; first boot ~30 s to the app
python3 lab.py status     # ports: cs 5551, ext_midi 5552, console 5553,
                          # qmp 5554, qmp_panel 5555, audio 5556, pcm 5557,
                          # vnc 5910, ssh 2022, usb_ssh 2222, panel 8765
python3 lab.py preload /path/to/mod/build/minimod.so   # copy to /run + restart ac50
python3 lab.py ssh 'systemctl status ac50; tail -f /run/minimod.log'
python3 lab.py stop
```

`MPCLAB_PORT_OFFSET=100` shifts every port (panel 8865) to avoid collisions with
an Android emulator.

### Panel protocol

Plain HTTP on the panel port. Controls come from `panel/controls.json` (45
physical controls: `PAD 1…16`, `SHIFT`, `DATA`, `K1..K3`, `FADER`, `SAMPLE`,
`SCREEN 1..3`, `CHOP`, `16 LEVELS`, …).

```sh
curl -X POST -H 'Content-Type: application/json' \
     -d '{"name":"SAMPLE","action":"press","value":100}' http://127.0.0.1:8765/control
curl -X POST -H 'Content-Type: application/json' \
     -d '{"name":"DATA","action":"turn","value":1}'     http://127.0.0.1:8765/control
curl -s http://127.0.0.1:8765/screen.png -o screen.png   # 320x240
curl -s 'http://127.0.0.1:8765/state?since=0'            # LEDs, pads, pots, sysEx
curl -X POST -H 'Content-Type: application/json' \
     -d '{"hex":"90 3c 64"}' http://127.0.0.1:8765/midi   # inject external MIDI
```

Actions: `press`, `release`, `turn` (relative 1 / 127), `set` (absolute 0–127).
Pad presses are notes on channel 10; the DATA encoder arrives as CC `0x64`;
LEDs come back as CC `b0 <id> <state>` (LED 75 = CHOP, 82 = PLAY). The app
ignores touch/tablet input.

Screenshots for byte-exact comparisons come either from `screen.png` or from
QMP (`human-monitor-command` → `screendump file.ppm`); hashing the PNG is a
cheap way to prove "no visual change".

### Reading the guest's memory

`tools/emulator/guestmem.py` reads `/proc/<pid>/mem` over SSH:

```sh
python3 guestmem.py maps
python3 guestmem.py base
python3 guestmem.py dump 0xffffe50bc620 0x9000 > /tmp/screen.bin
python3 guestmem.py f32  0xffffe50bc620+0x1f6c
```

The emulator tests use the same technique directly over SSH
(`dd if=/proc/<pid>/mem bs=1 skip=<addr> count=<n>`), locating the app base from
`/proc/<pid>/maps` and `g_screen` from `build/minimod.map`.

### Other lab tools (`tools/emulator/`)

| tool | use |
|---|---|
| `tap.c` | raw-ALSA ioctl recorder for the loopback (no libasound); optionally feeds silence so the app's input stream has a partner |
| `hwwatch.c` | perf hardware breakpoint (`HW_BREAKPOINT_W`) that prints the instruction writing an address in another process |
| `kmod/snd-mcuvirt.c` | virtual control-surface card (rawmidi + duplex PCM) for a plain VM; the app opens audio but capture still fails with `-5` |
| `agent/mcu-agent.c` | ALSA-sequencer "Control Surface" port bridged to Midi Through, logging every event |
| `capture-pads.py`, `compare-pads.py` | pad/LED capture and screen diffing |
| `qmp.py`, `console.py` | QMP and serial console helpers |
| `rsp_watch*.py` | gdbstub watchpoints (older lab) |

### Device-side harnesses from other addins

Two community addins are useful as *tools* on real hardware (not bundled):
`mpc-addin-remote` exposes the screen as DRM-captured PNG and injects touch into
the touchscreen evdev node, plus an MCP server with screenshot/tap/buttons/MIDI;
`mpc-addin-sample-draw-handler` exposes `/snap` (raw 320×240) and `/input`
(soft keys, dial, knobs) on `127.0.0.1:6740`. Both are documented, with their
installation rules and the DRM-master caveat, in
`ADDIN-ECOSYSTEM.md`.

## 3. In-process probes (the mod as a microscope)

> **On the Rust branch** the probe machinery below went away with the C: the
> shipped crate has no `MINIMOD_DEBUG` / `MINIMOD_LOG` build, no command channel
> and no heap probe, and it honours only `MINIMOD_TRIM_DB`. The recipe is kept
> because it is how the mechanisms in `MECHANISMS.md` were
> found; it builds from the last C revision (`main`, or the commit before the
> port in `docs/RUST-PORT.md`). Probe the Rust build with `/proc/<pid>/mem`
> reads of its exported `g_*` statics, as the emulator tests do.

The same library that ships was also the probe. Build the investigation variant
from that C revision:

```sh
zig cc -target aarch64-linux-gnu -shared -fPIC -O2 \
  -fno-omit-frame-pointer -mbranch-protection=standard -Wall -Wextra \
  -DMINIMOD_LOG=1 -DMINIMOD_DEBUG=1 \
  -o build/minimod-hpss.so src/minimod.c src/hpss.c src/spectral.c src/h3m_effect.c
```

A `MINIMOD_DEBUG=1` build enables (release builds ignore all of it):

* **structured logging** to `/run/minimod.log` (`mlog`);
* **a runtime command channel** `/run/minimod.chop` executed on the UI thread:
  `snap`/`diff` (whole-object snapshots and diffs), `snapb`/`diffb` (byte
  copies), `find <u32>`, `who`, `findval <f>`, `findq <u64>`, `reg`/`regdiff`,
  `poke <which> <v>`, `alloc`/`allocoff` (allocator probe), `wvec` (page watch
  on the slice vector), `repaint`, vtable dumps;
* **a heap probe thread** (`/run/minimod.heap`): `set <addr> <float>` (arbitrary
  write — debug only), `model <v>`, `findval`, `snap`/`diff`;
* **page watches** (`/run/minimod.watch`): `mprotect(PROT_READ)` a page and log
  the faulting instruction;
* **accessor-caller logging** via `__builtin_return_address` inside hooks, and
  **argument logging** of the app's own calls (this is how the pitch contract
  was captured).

All of it sat behind `#if MINIMOD_DEBUG` / `#if MINIMOD_LOG`; the shipped `.so`
contained none of it and honoured only `MINIMOD_TRIM_DB`.

Reading and writing the target's memory from inside uses `/proc/self/mem` with
**two separate descriptors** (`O_RDONLY` for `pread`, `O_WRONLY` for `pwrite`):
on this kernel a read through an `O_RDWR` descriptor returns `EIO`, which once
froze the UI.

Hook templates: `install_hook(base + offset, fn)` (Rust: `Hooks::install` in
[`mpc-sample-sdk/src/hook.rs`](https://github.com/ioma8/mpc-sample-sdk/blob/main/src/hook.rs)) allocates a relay slot and a
trampoline within ±128 MB, verifies the prologue and refuses if it starts
PC-relative. `FN(offset, type)` calls an app function by mod offset. The
technique and its rules are in `MODDING.md`.

## 4. Host harnesses

| harness | what it does |
|---|---|
| `mod/tests/emulator_*.py` | drive the panel, then read the model/audio independently: exact slice boundaries, trim frames, output WAV, status strings, pid/`NRestarts` |
| `rust/check.sh` | format, clippy (`-D warnings`, pedantic), a no-`unsafe` guard on the feature crate, rustdoc, the host unit tests and the golden fixtures that pin the DSP to the original C output, and the aarch64 release build |
| `tools/hpss/hpss.py` | reference HPSS implementation and the tuning bed; `wavio`, `wavdiff`, `excerpt`, `mix`, `onsets`, `spectral_chop` are the helpers |
| `tools/fit_*.py`, `probe_render.py` | converter-side fitting and render checks (see `converter/`) |
| `tools/device/probe-tanf.c` | `LD_PRELOAD` interposer on `tanf`: the app builds every JUCE IIR coefficient as `tanf(pi·f/fs)`, so this logs the **actual cutoff in Hz** each pad gets — ground truth a mixdown cannot give |
| `tools/device/probe_test.c` | host test for the probe's Hz conversion, dedup and log format |

The converter has its own ground-truth route: generated one-pad projects
exported by the device (`converter/docs/DEVICE-PROBE.md`).

## 5. Getting the firmware and the build

* The update image is `MPCSAMPLE-1.3.0.12-update.img`, an `AZ0x` container:
  `BOOT` raw, the rest xz-compressed. All inputs are SHA-256 checked against
  `inputs.sha256` in the lab.
* Partitions: `part1` boot (28,577,792 B), `part2` rootfs (427,117,568 B),
  `parr` recovery (28,303,360 B). The app is `/usr/bin/MPC Sample`.
* `strings -a -t x` on the image and `grep -aoE` for RTTI names are often faster
  than Ghidra for "does this class exist in this build".
* The lab build needs Docker (colima) once: `colima start --cpu 4 --memory 8 &&
  python3 lab.py build` (kernel ~15 min). Running needs QEMU 9+ and Python 3.9+.

## 6. Which tool for which question

| question | first tool |
|---|---|
| "what does this function do?" | `kuna decompile` or Ghidra `ResearchDecompile` |
| "who calls / references this?" | `tools/re/calls.py`, `fwxref.py`, `FindFunctionRefs` |
| "what class is this object?" | `classof.py`, RTTI dump, `DumpRTTI` |
| "which vtable slot is paint / render?" | `DumpVtable` + `classof.py --scan` on a live dump |
| "what does the app pass to itself here?" | probe build, log the hook arguments |
| "what changed when I did X?" | screen/object snapshot diff, `/proc/mem` diff, audio FFT |
| "does the feature work?" | emulator test reading the model/audio, not the log |
| "is it the same build?" | sha256 of the app and the deployed library |
| "what does the device do differently?" | `probe-tanf.so` on hardware, solo-project exports |

## 7. Static analysis

The Rust crates are linted by `rust/check.sh`: `cargo fmt --check`, clippy with
`all`, `pedantic` and `cargo` at `-D warnings`, `unreachable_pub`, `missing_docs`
and `unused_qualifications` denied, a rustdoc build with warnings denied, then the
tests and the aarch64 cross build. Every `unsafe` block in the SDK carries a
`// SAFETY:` comment, which clippy enforces. The feature crate (`crates/minimod`)
contains no `unsafe` at all and the script fails if one appears.

The SDK's `build-mod.sh` (called by `mod/build.sh`) adds two checks on the
shipped library: it fails on any unresolved symbol that is not versioned glibc (the firmware's loader would
reject the whole process), and it refuses a library that needs a glibc symbol
version newer than the device's 2.39.

The C-era audit (cppcheck, the Clang Static Analyzer and clang-tidy over
`mod/src`, all clean on the last C revision) is recorded in
`HISTORY.md`; the
findings it produced were ported to Rust, not merely dropped (the same section
lists where each landed).
