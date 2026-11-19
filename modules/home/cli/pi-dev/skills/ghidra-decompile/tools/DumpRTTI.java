import ghidra.app.script.GhidraScript;
public class DumpRTTI extends GhidraScript {
 String str(long p) throws Exception { StringBuilder s=new StringBuilder(); for(int i=0;i<160;i++){ int b=currentProgram.getMemory().getByte(toAddr(p+i))&255; if(b==0) break; s.append((char)b); } return s.toString(); }
 @Override public void run() throws Exception {
  for(String arg:getScriptArgs()) { long p=Long.decode(arg); long name=currentProgram.getMemory().getLong(toAddr(p+8)); int flags=currentProgram.getMemory().getInt(toAddr(p+16)); int n=currentProgram.getMemory().getInt(toAddr(p+20)); println("RTTI "+Long.toHexString(p)+" name="+str(name)+" flags="+flags+" bases="+n); for(int i=0;i<n;i++){long q=currentProgram.getMemory().getLong(toAddr(p+24+i*16L)); long off=currentProgram.getMemory().getLong(toAddr(p+32+i*16L)); long qname=currentProgram.getMemory().getLong(toAddr(q+8)); println("  "+i+" type="+Long.toHexString(q)+" name="+str(qname)+" offflags="+Long.toHexString(off));} }
 }
}
