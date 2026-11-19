import ghidra.app.script.GhidraScript;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.address.Address;

public class ProgramInfo extends GhidraScript {
    @Override public void run() throws Exception {
        println("name=" + currentProgram.getName());
        println("path=" + currentProgram.getExecutablePath());
        println("imageBase=" + currentProgram.getImageBase());
        println("language=" + currentProgram.getLanguageID());
        Address note = toAddr(0x1002d8);
        byte[] buildId = new byte[36];
        currentProgram.getMemory().getBytes(note, buildId);
        StringBuilder hex = new StringBuilder();
        for (byte value : buildId) hex.append(String.format("%02x", value & 0xff));
        println("buildIdNote=" + hex);
        for (long raw : new long[] {0x3e0c1a0L, 0x3e1c1a0L, 0x3d27800L}) {
            byte[] bytes = new byte[16];
            currentProgram.getMemory().getBytes(toAddr(raw), bytes);
            StringBuilder line = new StringBuilder();
            for (byte value : bytes) line.append(String.format("%02x", value & 0xff));
            println("bytes " + Long.toHexString(raw) + "=" + line);
        }
        for (MemoryBlock block : currentProgram.getMemory().getBlocks())
            println(block.getName() + " " + block.getStart() + "-" + block.getEnd() +
                    " file=" + block.getSourceName());
    }
}
