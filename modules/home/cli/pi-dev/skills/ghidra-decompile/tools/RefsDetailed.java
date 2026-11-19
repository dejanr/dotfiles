import ghidra.app.script.GhidraScript;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.listing.Function;
public class RefsDetailed extends GhidraScript {
 @Override public void run() throws Exception {
  for (String arg : getScriptArgs()) {
   var address = toAddr(Long.decode(arg));
   println("TARGET " + address);
   for (Reference ref : getReferencesTo(address)) {
    Function f = getFunctionContaining(ref.getFromAddress());
    println(ref.getFromAddress() + " " + (f == null ? "undefined" : f.getEntryPoint()+" "+f.getName()));
   }
  }
 }
}
