import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.Reference;

public class FindFunctionRefs extends GhidraScript {
    @Override public void run() throws Exception {
        for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
            String name = f.getName();
            if (!name.toLowerCase().contains(getScriptArgs()[0].toLowerCase())) continue;
            println("FUNCTION " + f.getEntryPoint() + " " + name + " ext=" + f.isExternal());
            for (Reference ref : getReferencesTo(f.getEntryPoint())) {
                Function caller = getFunctionContaining(ref.getFromAddress());
                println("  REF " + ref.getFromAddress() + " " + (caller == null ? "?" : caller.getName()));
            }
        }
    }
}
