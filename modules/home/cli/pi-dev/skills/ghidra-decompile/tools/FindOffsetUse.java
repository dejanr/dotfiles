import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.AddressSet;
import ghidra.program.model.scalar.Scalar;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;

public class FindOffsetUse extends GhidraScript {
    @Override
    public void run() throws Exception {
        long start = Long.decode(getScriptArgs()[0]);
        long end = Long.decode(getScriptArgs()[1]);
        long wanted = Long.decode(getScriptArgs()[2]);
        AddressSet range = new AddressSet(toAddr(start), toAddr(end));
        for (Instruction ins : currentProgram.getListing().getInstructions(range, true)) {
            for (int operand = 0; operand < ins.getNumOperands(); operand++) {
                for (Object input : ins.getOpObjects(operand)) {
                    if (input instanceof Scalar && ((Scalar) input).getUnsignedValue() == wanted) {
                        Function function = getFunctionContaining(ins.getAddress());
                        println(ins.getAddress() + " " +
                            (function == null ? "undefined" : function.getName()) + " " + ins);
                    }
                }
            }
        }
    }
}
