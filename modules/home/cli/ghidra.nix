{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.cli.ghidra;
in
{
  options.modules.home.cli.ghidra = {
    enable = lib.mkEnableOption "Ghidra and native reverse-engineering and debugging tools";
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      (with pkgs; [
        ghidra
        radare2
        file
        hexyl
        python3
      ])
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
        with pkgs;
        [
          binutils
          gdb
          strace
          ltrace
        ]
      )
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin (
        with pkgs.llvmPackages;
        [
          llvm
          lldb
        ]
      );

    home.sessionVariables.GHIDRA_DECOMPILE_SCRIPTS = "${./pi-dev/skills/ghidra-decompile}/tools";
  };
}
