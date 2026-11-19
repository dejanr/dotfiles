# HPSS Ghidra research scripts

These Java scripts run through GhidraMCP, using the setup in
[`TOOLING.md`](../docs/TOOLING.md#1-ghidra-and-the-mcp-bridge) and
[`SKILL.md`](../SKILL.md#4-use-the-bridge-for-the-persistent-project). The runner
preserves a single MCP session for initialization, instance connection and script
execution. What these scripts found, and which static paths were blind, is recorded
in [`RE-METHOD.md`](../docs/RE-METHOD.md).

Copy the Java files to Ghidra's script directory (`~/ghidra_scripts` in this
session). Start Ghidra with `GHIDRA_MCP_ALLOW_SCRIPTS=1`, open project
`mcpsamplebin`, then run from this directory:

```sh
python3 run_bridge.py --project mcpsamplebin ResearchDecompile.java 0x17580d0 0x153f0b0
python3 run_bridge.py --project mcpsamplebin ResearchDecompile.java 0x1aaaae0 0x219c5b0
python3 run_bridge.py --project mcpsamplebin --program knob.bin HpssRefs.java 0x153ed40
python3 run_bridge.py --project mcpsamplebin FindConst.java 100 3000
python3 run_bridge.py --project mcpsamplebin DumpVtable.java 0x6f212a0 70
```

The runner finds `bridge-mcp-ghidra` on `PATH` (override with `--bridge`) and
connects to the project named by `--project`; pass `--program` when more than one
program is open. Addresses are Ghidra VAs, not mod offsets.
ResearchDecompile creates a function at an explicit address if none exists;
this modifies Ghidra analysis, not the firmware binary. HpssEntry searches
backward for PACIASP and produces candidate entries requiring inspection.
HpssCommandTrace lists vtable slots and decompiles slots 4–7 when defined;
use ResearchDecompile explicitly for execute slot 8. Decompiled argument types
and calling conventions require validation before use in native code.
