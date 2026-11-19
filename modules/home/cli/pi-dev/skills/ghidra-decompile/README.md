# ghidra-decompile

An agent skill for decompiling binaries with Ghidra, plus the 22 Ghidra scripts it drives.

## Install

Node 22.20+. Installs into the current project; add `-g` for every project. Then copy `tools/*.java` to `~/ghidra_scripts`, or pass that directory as `-scriptPath` on headless runs.

Without the CLI, copy `SKILL.md` into your agent's skills directory as `ghidra-decompile/SKILL.md`.

## The idea that matters

**The cost is analysis, not decompilation.** A 114 MB stripped AArch64 image, imported once with `-noanalysis`, decompiled at one targeted function in **3.3 s**. Full auto-analysis of the same image takes hours, and is rarely needed to read one function.

So: import once, keep the project, decompile exact addresses. `SKILL.md` is the method.

## What's here

- `SKILL.md` — pinning addresses to the image base, headless decompile, the MCP bridge, validating the output, and a symptom → cause → fix table
- `tools/` — 22 scripts (decompile at address, vtable/RTTI dumps, xrefs, `PACIASP` entry scan) and a stdio runner, with script-by-script notes in `tools/README.md`
- [`TOOLING.md`](docs/TOOLING.md) and [`RE-METHOD.md`](docs/RE-METHOD.md) — the tooling and the method these scripts came out of

Needs Ghidra, verified on 12.2. The bridge path also needs [bethington/ghidra-mcp](https://github.com/bethington/ghidra-mcp) and `uv`; headless decompilation needs neither.

## The trap

`GhidraMCP-7.0.0.zip` is built for **Ghidra 12.1.4**. Against 12.2, every decompile fails with `ghidra/program/model/lang/SleighLanguageDescription`. Build the `chore/ghidra-12.2` branch, then confirm `extension.properties` reports `version=12.2`. The full sequence is in `SKILL.md`.
