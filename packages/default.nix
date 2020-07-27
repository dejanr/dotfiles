[
  (self: super: with super; {
    my = {
      pragmatapro = super.callPackage ./pragmatapro.nix {};
      ant-dracula = (callPackage ./ant-dracula.nix {});
      doom-emacs = (callPackage ./doom-emacs.nix {});
      cached-nix-shell = import (import ../nix/sources.nix).cached-nix-shell {};
    };

    nur = import (import ../nix/sources.nix).nur {
      inherit super;
    };

    # Occasionally, "stable" packages are broken or incomplete, so access to the
    # bleeding edge is necessary, as a last resort.
    unstable = import (import ../nix/sources.nix).nixpkgs-unstable { inherit config; };
  })

  # emacsGit
  (import (import ../nix/sources.nix).emacs-overlay)
]
