import ghidra.app.script.GhidraScript;
public class DumpWords extends GhidraScript {
 @Override public void run() throws Exception {
  for(String arg:getScriptArgs()) { long p=Long.decode(arg); println("AT "+Long.toHexString(p)); for(long o=-0x30;o<=0x30;o+=8) { var a=toAddr(p+o); println(a+" = "+Long.toHexString(currentProgram.getMemory().getLong(a))); } }
 }
}
