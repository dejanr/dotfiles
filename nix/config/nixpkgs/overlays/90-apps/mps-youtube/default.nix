{ lib, python3Packages, fetchFromGitHub }:

with python3Packages;

buildPythonApplication rec {
  pname = "mps-youtube";
  version = "unstable-2020-01-28";

  src = fetchFromGitHub {
    owner = "mps-youtube";
    repo = "mps-youtube";
    rev = "4c6ee0f8f4643fc1308e637b622d0337bf9bce1b";
    sha256 = "";
  };

  propagatedBuildInputs = [ pafy ];

  # disabled due to error in loading unittest
  # don't know how to make test from: <mps_youtube. ...>
  doCheck = false;

  # before check create a directory and redirect XDG_CONFIG_HOME to it
  preCheck = ''
    mkdir -p check-phase
    export XDG_CONFIG_HOME=$(pwd)/check-phase
  '';

  meta = with lib; {
    description = "Terminal based YouTube player and downloader";
    homepage = "https://github.com/mps-youtube/mps-youtube";
    license = licenses.gpl3;
    maintainers = with maintainers; [ koral odi ];
  };
}
