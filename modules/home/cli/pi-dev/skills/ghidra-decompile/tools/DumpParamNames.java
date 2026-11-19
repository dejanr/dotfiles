import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.mem.Memory;

public class DumpParamNames extends GhidraScript {
    private String cstr(Memory m, long ptr) throws Exception {
        if (ptr == 0) return "";
        Address a = toAddr(ptr);
        StringBuilder s = new StringBuilder();
        for (int i = 0; i < 96; i++) {
            int b = m.getByte(a.add(i)) & 0xff;
            if (b == 0) break;
            if (b < 32 || b > 126) return "";
            s.append((char)b);
        }
        return s.toString();
    }
    @Override public void run() throws Exception {
        Address base = toAddr(Long.decode(getScriptArgs()[0]));
        int count = Integer.parseInt(getScriptArgs()[1]);
        int stride = getScriptArgs().length > 2 ? Integer.decode(getScriptArgs()[2]) : 0x30;
        Memory m = currentProgram.getMemory();
        for (int i = 0; i < count; i++) {
            Address e = base.add((long)i * stride);
            long name = m.getLong(e);
            long label = m.getLong(e.add(8));
            int def = m.getInt(e.add(0x28));
            println(i + "\t" + cstr(m, name) + "\t" + cstr(m, label) + "\t" +
                String.format("%08x", def));
        }
    }
}
