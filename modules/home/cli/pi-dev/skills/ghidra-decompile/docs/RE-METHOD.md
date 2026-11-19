# How the reverse engineering is done

> Notes from reverse-engineering the Akai MPC Sample firmware.
> Companion documents (`MECHANISMS.md`, `HISTORY.md`, `HYPOTHESES.csv`) are not published;
> they are referenced by name only.

The method that produced every mechanism in `MECHANISMS.md`:
how claims are ranked, the loop that produced the breakthroughs, what paid off
most, which paths looked reasonable and were wrong, and the rules that keep a
mod safe inside someone else's process. Tool usage is in
[`TOOLING.md`](TOOLING.md); the chronological record is in
`HISTORY.md`.

## 1. Ground-truth hierarchy

Every claim is ranked, and every experiment is designed to move one step up:

1. **The shipped artifact.** Same binary hash in the emulator as on the device
   (`b6584cba…`), so emulator results transfer. The autorun package pins the
   first 4 KiB as well.
2. **Measured audio or measured memory.** PCM recordings, correlation, FFT,
   register and argument captures, model fields read out of `/proc/<pid>/mem`.
   Never "it sounds right".
3. **Decompiled code.** Ghidra, after the runtime contract is known — it
   explains *why*, but it does not prove what runs.
4. **A reference implementation.** Another mod (SampQOL, am-mod) loaded in the
   same emulator and measured. It proves possibility and gives hook addresses.
5. **Hypothesis or intuition.** Cheapest and weakest; used only to pick the next
   experiment.

Two rules follow from it:

* **When a measurement and a hypothesis disagree, the measurement wins — but
  first prove the measurement is clean.** More time was lost to a dirty
  measurement (a knob change that had not registered, a stale pointer, the wrong
  address space) than to missing theory.
* **When a decompile and a measurement disagree, the measurement wins.** The
  decompiled prototype can mislead about argument types; the registers at a live
  call settle it.

## 2. The loop

1. **Confirm the binary.** Hash the app, verify the copy in the lab, check the
   firmware pin. A mismatched build invalidates every offset.
2. **Find a working reference.** Stock behaviour or another mod, measured with
   the same stimulus. Record what "works" looks like as numbers.
3. **Reproduce the gesture under a probe.** Run the real thing in the emulator
   (panel click, pad press, knob turn) and log the data structure at the *last
   common point* — usually the dispatcher both paths share.
4. **Diff two paths.** Physical pad vs MIDI, trimmed vs untrimmed, before vs
   after one knob detent. A 64-byte event diff or a 4-word screen diff is worth
   more than a day of speculation.
5. **Instrument the function the app already uses** and log *its* arguments, not
   yours. The pitch breakthrough came from logging the app's own call to the
   property setter (`w3 = level − originalPad`), not from inventing an event.
6. **Reproduce that call with the firmware's own contract**, then verify with a
   measurement (audio, memory, screenshot hash) and a state check (pid,
   `NRestarts`, screen bytes).
7. **Decompile to confirm the contract**, document ranges and limits, and turn
   the measurement into a regression test.

The result of step 7 is the difference between "we believe" and a test that
fails when the firmware changes. Every emulator test in `mod/tests/` reads the
model or the audio independently; none trusts the mod's own log.

## 3. What proved super useful

Ranked by how much time each saved.

1. **A working reference implementation as an oracle.** Loading SampQOL v0.1.5
   in the same emulator and playing the same notes: correlation 0.997 at MIDI 60
   on the selected pad, 1.000 after selecting another pad, while stock/minimod
   sat at 0.05. Its own log then listed the exact hook map
   (`keys-evin 0x211b090`, `keys-nrsend 0x211a690`, `keys-prognote 0x286fcf0`).
   That turned weeks of guessing into a short list of addresses.
2. **Byte-level capture at the dispatcher, diffed between two paths.** The note
   event is a compact struct; dumping 64 bytes for a physical pad and for a
   synthesised note exposed `event+0x14` (property mask), `+0x16` (property 0),
   `+0x30` (pad/slot) one field at a time.
3. **Instrumenting the app's own call.** Hooking the already-known
   `pitch_off` wrapper and logging the arguments the firmware passes to itself
   gave the exact semitone contract. Reproducing the firmware's own call, with
   the firmware's arguments, is the single most reliable construction in this
   project.
4. **Whole-object snapshot diffing with a human operator at the panel.** The
   user's two remarks — "K1/K2 move the selected chop's boundaries" and "Split
   works only in Manual" — became one experiment: snapshot every word of every
   slice on each button/knob event, have the user perform the gesture, and diff.
   The result (`slice0 +0xd0 2465 → 4906`, mirrors carried) was unambiguous and
   ended the field hunt. The same technique later located the native trim frames
   at `layer+0x7b8/+0x810/+0x868`.
5. **A controlled stimulus.** A 3 s 220 Hz sine on the selected pad turned
   pitch claims into arithmetic (48 → 110.4, 60 → 220.7, 65 → 293.4 Hz). A
   guitar phrase cannot do this; harmonics and FFT peaks lie.
6. **Driving the native API instead of writing fields.** Vtable dumps, RTTI
   names and call-site searches found the slice container's own
   `reset`/`insert`/`reconcile`/`select` and the chop binding's model callback.
   Using them removed every rebuild and repaint problem at once, and is now the
   house pattern for "make the app edit its own model".
7. **A host-side harness that reads the model from `/proc/<pid>/mem`.** The
   emulator tests assert exact slice boundaries, exact trim frames, exact status
   strings — independent of the mod's logging. This caught test drift and
   firmware behaviour that a screenshot cannot see.
8. **Reading the app's own status/limit strings.** RTTI names
   (`Air::H3M::StereoReverb`), undo labels (`"Insert Slice"`), telemetry keys
   (`"slices_added"`) and error strings are cheap, exact anchors for finding a
   class or a code path.

## 4. Blind paths, and why they were blind

| path | why it failed | the lesson |
|---|---|---|
| Treating a changed float property as the DATA detent | `0x13bb930` is a generic value setter with de-duplication; the encoder arrives on a different integer signal | never infer an input source from "it changed when I turned it" |
| Restoring a sample backup at remembered offsets | the app re-serialises and re-dithers its project working copy, so the `data` offset moves | never write to the app's files; treat the working copy as unstable |
| Searching the heap for the slice "editor" object | it was never observed; the Chop UI edits the container directly | a decompiled command API is not proof of a live path |
| Reading `layer+0xb0…` as `SlicePoints` | those words are inline `std::string` data | verify a struct by diffing real events, not by shape |
| Polling for a page switch inside the same callback | the switch is asynchronous | model work belongs to the paint pass |
| Breakpointing a function the mod had hooked | `BRK` overwrote the mod's `B`, and "restore" wrote back the wrong bytes | never breakpoint a patched entry; probe the caller |
| Using Ghidra VAs as mod offsets | every hook sat `0x100000` past its target, so "the hook never fires" was an artifact | write the address rule next to every table; it cost a whole pass |
| Trusting an older doc's conclusion | several early notes (property path, −40 dB, marker overlay, 3-row menu) were superseded | docs are evidence too: date them, and retest when behaviour changes |
| Screenshot-only verification | a screenshot diff cannot tell a toast from a repaint | combine screenshots with model or audio reads |
| Testing against a debug build | the AutoTrim test asserted on a log line that release builds never write | tests must run against the artifact you ship |

Cross-checks that repeatedly paid off: pid and `NRestarts` unchanged; the
dispatcher's first bytes (`d503233f` stock vs `155f947c` hooked); the deployed
library's sha256; exact boundary frames read back from the model.

## 5. Hardening rules

Learned by reviewing the earlier implementation and by crashes that reached the
app. They are requirements, not preferences.

* **Never return from a fatal signal handler.** The first implementation caught
  `SIGSEGV`/`SIGBUS`/`SIGILL`/`SIGABRT` and returned. That hides real crashes and
  can loop. Debug-only fault recovery (`sigsetjmp` around a guarded probe call)
  is acceptable; a process-wide returning handler is not.
* **Refuse rather than guess.** Verify the firmware hash, the hooked function's
  prologue, the screen vtable, the sample identity, the chop type. A mismatch
  must turn into "no mod" or an explicit status, never a wrong write.
* **Keep `/proc/self/mem` access single-direction.** `pread` on an `O_RDWR`
  descriptor returns `EIO` on this kernel; use one cached `O_RDONLY` and one
  `O_WRONLY` descriptor. A frozen UI was the symptom.
* **Compile the investigation surface out of release.** The arbitrary-write
  command channel, page watches, snapshots, allocator probe and probe threads
  live behind `#if MINIMOD_DEBUG`; logger state behind `#if MINIMOD_LOG`. A
  release build must honour no environment switch except the documented
  `MINIMOD_TRIM_DB`.
* **Keep native Extract lifetime explicit.** Emulator synth and reverb traces on
  firmware 1.3.0.12 show the handler and command execute nested on the same UI
  thread. The SDK checks assignment and writer completion after the native call;
  it retains a borrowed seed if a constructed command is still pending. The
  native call itself cannot be interrupted by this check. Earlier device-era
  notes describe a different execution order; see
  `re/hpss/extract-dispatch-investigation.md`.
* **Never allocate app-owned objects from the mod.** The app's allocator is not
  libc's; a `Slice` or `Sample` allocated by the mod cannot be freed by the app.
* **Do model work on the UI thread.** Input hooks publish a request; the paint
  hook advances a one-phase-per-pass state machine; the worker touches only its
  own buffers.
* **Check the thing you are about to act on.** Screen pointer identity before a
  model call, sample identity before committing a transform, chop type after
  setting it, every slice boundary after insert.

## 6. Pitfalls specific to this target

* **Two address spaces.** Ghidra VA = mod offset + `0x100000`; runtime =
  `base + mod offset`. Every table in these docs says which one it uses.
* **The screen object is recreated.** Cache it only from the paint hook
  (`g_screen`), never across restarts.
* **Pointers captured from the page can be stale or stack temporaries.** The
  `SamplePage_Ctor` capture looked like a stack address; pad loads pass stack
  temporaries (`FUN_0290dca0(page, 0, …)` means "reset").
* **The app owns its audio and MIDI endpoints.** Do not open ALSA devices; hook
  the native writer or the native event path instead.
* **Pad MIDI In is not persisted.** It resets on every start; several false
  "it does not work" runs were this.
* **The emulator is not the device.** It has no Bluetooth, no WiFi and ignores
  touch input; "emulator-verified" is recorded as such, never as hardware proof.
* **The app rewrites its working copies.** Sample files under `TempProjects` may
  change format/layout (re-dither ±2 LSB, `JUNK` chunk shrink). Read them; never
  write them.
* **Tests drift with the UI.** When the menu grew from three rows to seven, two
  tests kept asserting the old geometry. Derive geometry from the rendered
  screen or the model, and prefer model reads over log lines.

## 7. Reusable checklist for the next firmware feature

1. Confirm the binary hash matches the device.
2. Find a working reference (stock behaviour or another mod) and measure it.
3. Capture the data structure at the last common point and diff two paths.
4. Instrument the function the firmware already uses; log *its* arguments.
5. Reproduce that call with the firmware's own contract.
6. Verify state (bytes, model, screens) before every measurement; use a
   controlled signal.
7. Decompile the functions involved; record ranges, limits and failure modes.
8. Turn the measurement into a test that reads the model or audio independently.
9. Record the hypothesis, the test and the verdict in `HYPOTHESES.csv` as you go
   — it is cheap while you work and expensive to reconstruct later.

## 8. Hypothesis ledger

`HYPOTHESES.csv` holds every hypothesis with its test and
verdict (proved / disproved / inconclusive). It is part of the method: it stops
the next session from re-running an experiment that already failed, and it
records *why* a plausible route was abandoned — which is usually more valuable
than the final answer.
