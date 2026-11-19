import ghidra.app.script.GhidraScript;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.listing.Function;
public class HpssRefs extends GhidraScript { public void run() throws Exception {for(String a:getScriptArgs())for(Reference r:getReferencesTo(toAddr(Long.decode(a)))){Function f=getFunctionContaining(r.getFromAddress());println(r.getFromAddress()+" "+(f==null?"undefined":f.getName()));}}}
