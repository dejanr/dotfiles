import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.DataIterator;

public class FindStrings extends GhidraScript {
    @Override public void run() throws Exception {
        String needle = getScriptArgs()[0].toLowerCase();
        DataIterator it = currentProgram.getListing().getDefinedData(true);
        while (it.hasNext()) {
            Data data = it.next();
            Object value = data.getValue();
            if (value != null) {
                String text = value.toString();
                if (text.toLowerCase().contains(needle))
                    println(data.getAddress() + " " + text);
            }
        }
    }
}
