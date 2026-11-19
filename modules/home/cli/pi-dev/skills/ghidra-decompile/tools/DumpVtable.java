import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.mem.Memory;

public class DumpVtable extends GhidraScript {
    @Override public void run() throws Exception {
        Address base = toAddr(Long.decode(getScriptArgs()[0]));
        int count = Integer.parseInt(getScriptArgs()[1]);
        Memory memory = currentProgram.getMemory();
        for (int i = 0; i < count; i++) {
            Address slot = base.add((long)i * 8);
            println(String.format("%s[%02d] -> %s", slot, i,
                    toAddr(memory.getLong(slot))));
        }
    }
}
