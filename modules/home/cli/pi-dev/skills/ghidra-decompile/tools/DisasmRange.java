import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Instruction;

public class DisasmRange extends GhidraScript {
    @Override public void run() throws Exception {
        Address pc = toAddr(Long.decode(getScriptArgs()[0]));
        int count = Integer.parseInt(getScriptArgs()[1]);
        for (int i = 0; i < count; i++) {
            Instruction ins = getInstructionAt(pc);
            if (ins == null) { println(pc + " <no instruction>"); pc = pc.add(4); }
            else { println(ins.getAddress() + " " + ins.toString()); pc = ins.getMaxAddress().add(1); }
        }
    }
}
