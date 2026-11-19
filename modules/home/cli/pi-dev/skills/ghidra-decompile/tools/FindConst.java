import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.lang.OperandType;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.scalar.Scalar;

public class FindConst extends GhidraScript {
    @Override
    public void run() throws Exception {
        long want = Long.decode(getScriptArgs()[0]);
        int limit = getScriptArgs().length > 1 ? Integer.parseInt(getScriptArgs()[1]) : 200;
        int shown = 0;
        InstructionIterator it = currentProgram.getListing().getInstructions(true);
        while (it.hasNext() && shown < limit) {
            Instruction ins = it.next();
            for (int i = 0; i < ins.getNumOperands() && shown < limit; i++) {
                if (ins.getOperandType(i) != OperandType.SCALAR) continue;
                Scalar s = ins.getOpObjects(i).length == 1 && ins.getOpObjects(i)[0] instanceof Scalar
                    ? (Scalar) ins.getOpObjects(i)[0] : null;
                if (s == null || s.getValue() != want) continue;
                Address a = ins.getAddress();
                Function f = getFunctionContaining(a);
                println(a + " " + (f == null ? "undefined" : f.getName() + "@" + f.getEntryPoint())
                    + " : " + ins);
                shown++;
            }
        }
        println("total shown=" + shown);
    }
}
