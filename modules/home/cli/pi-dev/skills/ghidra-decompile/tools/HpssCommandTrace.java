import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
public class HpssCommandTrace extends GhidraScript {
 public void run() throws Exception {
  DecompInterface d=new DecompInterface();d.openProgram(currentProgram);
  try { for(String arg:getScriptArgs()) {
   long a=Long.decode(arg); println("VTABLE "+arg);
   for(int i=0;i<12;i++) {
    long p=getLong(toAddr(a+i*8)); Function f=getFunctionAt(toAddr(p));
    println("slot "+i+" "+Long.toHexString(p)+" "+(f==null?"":f.getName()));
    if(f!=null && i>=4 && i<=7) { DecompileResults r=d.decompileFunction(f,90,monitor);if(r.decompileCompleted())println(r.getDecompiledFunction().getC()); }
   }
  }} finally {d.dispose();}
 }
}
