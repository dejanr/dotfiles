import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.Reference;
public class HpssFindExtract extends GhidraScript {
 public void run() throws Exception {
  DataIterator it=currentProgram.getListing().getDefinedData(true);
  while(it.hasNext() && !monitor.isCancelled()) {
   Data d=it.next(); Object v=d.getValue();
   if(v instanceof String && ((String)v).toLowerCase().contains("extract")) {
    println(d.getAddress()+" "+v);
    for(Reference r:getReferencesTo(d.getAddress())) {
     Function f=getFunctionContaining(r.getFromAddress());
     println("  "+r.getFromAddress()+" "+(f==null?"no function":f.getName()));
    }
   }
  }
 }
}
