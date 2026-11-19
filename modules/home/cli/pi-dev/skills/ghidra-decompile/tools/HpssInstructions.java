import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Instruction;
public class HpssInstructions extends GhidraScript {public void run() throws Exception {for(String a:getScriptArgs()){println(a);Instruction i=getInstructionAt(toAddr(Long.decode(a)));for(int n=0;i!=null&&n<50;n++,i=i.getNext()){println(i.getAddress()+" "+i);if(i.getMnemonicString().equals("ret"))break;}}}}
