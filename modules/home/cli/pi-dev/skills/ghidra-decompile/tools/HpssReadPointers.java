import ghidra.app.script.GhidraScript;
public class HpssReadPointers extends GhidraScript { public void run() throws Exception { for(String a:getScriptArgs())println(a+" -> "+Long.toHexString(getLong(toAddr(Long.decode(a)))));}}
