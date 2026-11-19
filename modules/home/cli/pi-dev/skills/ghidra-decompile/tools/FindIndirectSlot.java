import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;

/** Find ARM64 indirect calls whose vtable load uses a requested byte offset. */
public class FindIndirectSlot extends GhidraScript {
    @Override
    public void run() throws Exception {
        String slot = getScriptArgs().length == 0 ? "0x58" : getScriptArgs()[0];
        int hits = 0;
        FunctionIterator functions = currentProgram.getFunctionManager().getFunctions(true);
        while (functions.hasNext() && !monitor.isCancelled()) {
            Function function = functions.next();
            InstructionIterator instructions = currentProgram.getListing()
                .getInstructions(function.getBody(), true);
            Instruction[] recent = new Instruction[8];
            int count = 0;
            while (instructions.hasNext() && !monitor.isCancelled()) {
                Instruction instruction = instructions.next();
                String mnemonic = instruction.getMnemonicString().toUpperCase();
                if (mnemonic.equals("BLR") || mnemonic.equals("BR")) {
                    for (int i = 0; i < count; i++) {
                        Instruction prior = recent[i];
                        String text = prior.toString().toLowerCase();
                        String priorMnemonic = prior.getMnemonicString().toUpperCase();
                        if ((priorMnemonic.startsWith("LDR") ||
                             priorMnemonic.startsWith("LDUR")) &&
                            text.matches(".*\\[x[0-9]+, #" + slot.toLowerCase() + "\\].*")) {
                            println(function.getEntryPoint() + " " + function.getName() +
                                " -> " + instruction.getAddress() + " via " + prior);
                            hits++;
                            break;
                        }
                    }
                }
                if (count < recent.length) recent[count++] = instruction;
                else {
                    System.arraycopy(recent, 1, recent, 0, recent.length - 1);
                    recent[recent.length - 1] = instruction;
                }
            }
        }
        println("hits=" + hits);
    }
}
