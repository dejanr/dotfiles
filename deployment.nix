with (import ./nix).lib;
let
  hosts = (import ./machines.nix {}).hosts;
  mkSystem = name: arch:
    let
      system = arch;
      pkgs = (import ./nix).pkgs { inherit system; config.allowUnfree = true; config.allowUnsupportedSystem = true; };
    in { ... }: {
      imports = [ (./nix/config/nixpkgs/machines + "/${name}/configuration.nix") ];
      nixpkgs.pkgs = pkgs;
      deployment.substituteOnDestination = true;
    };
  machines = mapAttrs mkSystem hosts;
in
{
  network = {
    description = "Dejan's Machines";
  };

  "10.147.17.20" = machines.home;
  "10.147.17.40" = machines.theory;
  "10.147.17.60" = machines.homelab;
  "10.147.17.70" = machines.office;
}
