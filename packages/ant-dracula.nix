{ stdenv, fetchurl, gtk-engine-murrine }:

stdenv.mkDerivation rec {
  pname = "ant-dracula-theme";
  version = "1.3.0";

  src = fetchurl {
    url = "https://github.com/EliverLara/Ant-Dracula/releases/download/v${version}/Ant-Dracula.tar";
    sha256 = "09lcnysb6r1rm9fgxhpqgv4amjxwhv675lc5jbjwikz5m4nfnnga";
  };

  propagatedUserEnvPkgs = [
    gtk-engine-murrine
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/themes/Ant-Dracula
    cp -a * $out/share/themes/Ant-Dracula
    rm -r $out/share/themes/Ant-Dracula/{Art,LICENSE,README.md,gtk-2.0/render-assets.sh}
    runHook postInstall
  '';

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = "09lcnysb6r1rm9fgxhpqgv4amjxwhv675lc5jbjwikz5m4nfnnga";

  meta = with stdenv.lib; {
    description = "A flat and light theme with a modern look";
    homepage = https://github.com/EliverLara/Ant-Dracula;
    license = licenses.gpl3;
    platforms = platforms.all;
    maintainers = [
      maintainers.pbogdan
    ];
  };
}
