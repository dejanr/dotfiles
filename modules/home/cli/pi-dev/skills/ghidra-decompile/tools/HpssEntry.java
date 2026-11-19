import ghidra.app.script.GhidraScript;
public class HpssEntry extends GhidraScript { public void run() throws Exception {for(String a:getScriptArgs()){long v=Long.decode(a);for(long p=v;p>v-0x3000;p-=4)if(getInt(toAddr(p))==0xd503233f){println(a+" entry "+Long.toHexString(p));break;}}}}
