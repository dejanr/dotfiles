{ wine, prefix }:
''
  #!/usr/bin/env sh

  cd ~/${prefix}/drive_c/Program\ Files\ \(x86\)/Entropia\ Universe
  WINEARCH=win32 WINEDEBUG=-all WINEPREFIX=~/${prefix} ${wine}/bin/wine bin32/ClientLoader.exe 1>/dev/null 2>/dev/null
''
