import ghidra.app.script.GhidraScript;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.address.Address;
public class FindPointerValues extends GhidraScript {
 @Override public void run() throws Exception {
  for (String arg : getScriptArgs()) {
   long target=Long.decode(arg); println("TARGET "+Long.toHexString(target));
   for (MemoryBlock b: currentProgram.getMemory().getBlocks()) {
    if (!b.isInitialized() || b.getSize()>0x10000000L) continue;
    Address start=b.getStart(); long size=b.getSize();
    for (long off=0; off+8<=size; off+=8) {
     if ((off&0xfffff)==0 && monitor.isCancelled()) return;
     long value=currentProgram.getMemory().getLong(start.add(off));
     if (value==target) println(start.add(off)+" block="+b.getName());
    }
   }
  }
 }
}
