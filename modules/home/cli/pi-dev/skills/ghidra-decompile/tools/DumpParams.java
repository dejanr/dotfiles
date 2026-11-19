import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.mem.Memory;

/** Inspect H3 parameter descriptors: <base> [count] [stride]. */
public class DumpParams extends GhidraScript {
    @Override
    public void run() throws Exception {
        Address base = toAddr(Long.decode(getScriptArgs()[0]));
        int count = getScriptArgs().length > 1 ? Integer.parseInt(getScriptArgs()[1]) : 18;
        int stride = getScriptArgs().length > 2 ? Integer.decode(getScriptArgs()[2]) : 0x30;
        Memory memory = currentProgram.getMemory();
        for (int i = 0; i < count; i++) {
            Address entry = base.add((long)i * stride);
            println("param " + i + " @ " + entry);
            for (int offset = 0; offset < stride; offset += 8) {
                long word = memory.getLong(entry.add(offset));
                String pointed = "";
                if (word > 0 && currentProgram.getMemory().contains(toAddr(word))) {
                    ghidra.program.model.listing.Data data =
                        currentProgram.getListing().getDataAt(toAddr(word));
                    if (data != null && data.hasStringValue()) pointed = " " + data.getValue();
                }
                println(String.format("  +%02x %016x%s", offset, word, pointed));
            }
        }
    }
}
