{
  lib,
  buildGo126Module,
  fetchFromGitHub,
  git,
  installShellFiles,
  stdenv,
  icu,
  pkg-config,
}:

buildGo126Module rec {
  pname = "beads";
  version = "0.49.3";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "beads";
    rev = "v${version}";
    hash = "sha256-NMEMYDXnSBzumbxsjBQ2/wRPj+UotRQCLY8D6iimBM4=";
  };

  vendorHash = "sha256-yKlJkkc1h4GmirWMYL2f1Enp2IihMR7QWYq887kvS24=";

  subPackages = [ "cmd/bd" ];

  doCheck = false;

  nativeBuildInputs = [
    git
    installShellFiles
    pkg-config
  ];

  buildInputs = [ icu ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd bd \
      --bash <($out/bin/bd completion bash) \
      --fish <($out/bin/bd completion fish) \
      --zsh <($out/bin/bd completion zsh)
  '';

  meta = {
    description = "Lightweight memory system for AI coding agents with graph-based issue tracking";
    homepage = "https://github.com/steveyegge/beads";
    license = lib.licenses.mit;
    mainProgram = "bd";
  };
}
