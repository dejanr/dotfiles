{ pkgs }:
pkgs.writeShellScriptBin "wine-prefix" ''
  if ! command -v winepath; then
   >&2 echo "$(basename "$0"): No winepath binary in path. Run with wine available"
   exit 1
  fi
  export WINEPREFIX="''${WINEPREFIX:-$HOME/.wine}"
  echo "Preparing prefix $WINEPREFIX for gaming"

  set -euo pipefail

  echo "Killing running wine processes/wineserver"
  wineserver -k || true

  echo "Running wineboot -u to update prefix"
  WINEDEBUG=-all wineboot -u; sleep 1

  echo "Stopping processes in session"
  wineserver -k || true

  echo "Installing dxvk DLLs"
  ${pkgs.dxvk}/bin/setup_dxvk.sh install -f

  echo "Adding native DllOverrides"
  for dll in dxgi d3d9 d3d10core d3d11 d3d12; do
    wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v $dll /d native /f >/dev/null 2>&1
  done
''
