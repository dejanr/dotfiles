{pkgs, macroFile}: ''
cat ${macroFile} | ${pkgs.xmacro}/bin/xmacroplay -d 30 :0.0
''
