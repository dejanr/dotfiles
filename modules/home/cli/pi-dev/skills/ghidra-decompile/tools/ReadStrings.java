import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;

public class ReadStrings extends GhidraScript {
    @Override public void run() throws Exception {
        for (String arg : getScriptArgs()) {
            Address a = toAddr(Long.decode(arg));
            StringBuilder s = new StringBuilder();
            for (int i = 0; i < 128; i++) {
                int b = getByte(a.add(i)) & 0xff;
                if (b == 0) break;
                s.append((char)b);
            }
            println(a + "  " + s);
        }
    }
}
