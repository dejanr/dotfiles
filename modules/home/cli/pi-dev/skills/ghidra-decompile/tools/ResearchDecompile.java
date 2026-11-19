import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;

public class ResearchDecompile extends GhidraScript {
    @Override
    public void run() throws Exception {
        DecompInterface decompiler = new DecompInterface();
        decompiler.openProgram(currentProgram);
        try {
            for (String arg : getScriptArgs()) {
                Address address = toAddr(Long.decode(arg));
                Function function = getFunctionAt(address);
                if (function == null) function = getFunctionContaining(address);
                if (function == null) { disassemble(address); function = createFunction(address, null); }
                println("===== " + arg + " => " +
                    (function == null ? "no function" : function.getName() + " @ " + function.getEntryPoint()) + " =====");
                if (function == null) continue;
                DecompileResults result = decompiler.decompileFunction(function, 120, monitor);
                println(result.decompileCompleted()
                    ? result.getDecompiledFunction().getC()
                    : "/* decompile failed: " + result.getErrorMessage() + " */");
            }
        } finally {
            decompiler.dispose();
        }
    }
}
