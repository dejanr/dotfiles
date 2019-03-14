{ pkgs ? import <nixpkgs> {}
, repoUrl ? "https://github.com/dejanr/dotfiles.git"
, channel ? "nixpkgs-unstable"
, targetDir ? "$HOME/.dotfiles"
}:

let
  install = pkgs.writeScript "install" ''
    set -e

    nix-channel --add https://nixos.org/channels/${channel} nixpkgs
    nix-channel --update nixpkgs

    if [ ! -d ${targetDir} ]; then
        echo "setting up dotfiles repository" >&2
        mkdir -p ${targetDir}
        git clone --depth=1 ${repoUrl} ${targetDir}
    fi

    ${link}
  '';

  link = pkgs.writeScript "link" ''
    set -e

    link() {
      from="$1"
      to="$2"
      echo "link '$from' to '$to'"
      rm -f $to
      ln -s "$from" "$to"
    }

    mkdir -p ~/.config

    for main in $(find ${targetDir} -maxdepth 2 -mindepth 2 ! -path '*.git*' | sort)
    do
      name=$(basename $main)

      if [ -d $main ]; then
        echo "mkdir $HOME/.$name"
        mkdir -p $HOME/.$name

        for location in $(find $main -maxdepth 1 -mindepth 1 | sort)
        do
          dot=$(basename $location)
          link $location $HOME/.$name/$dot
        done
      fi

      if [ -f $main ]; then
        link $main $HOME/.$name
      fi
    done
  '';

  unlink = pkgs.writeScript "unlink" ''
    set -e

    for main in $(find ${targetDir} -maxdepth 2 -mindepth 1 ! -path '*.git*' | sort -r)
    do
      name=$(basename $main)

      if [ -L $HOME/.$name ]; then
        echo "unlink $HOME/.$name"
        unlink $HOME/.$name
      fi

      if [ -d $HOME/.$name ]; then
        for location in $(find $main -maxdepth 1 -mindepth 1)
        do
          dot=$(basename $location)

          if [ -L $HOME/.$name/$dot ]; then
            echo "unlink $HOME/.$name/$dot"
            unlink $HOME/.$name/$dot
          fi
        done

        echo "rmdir $HOME/.$name"
        find $HOME/.$name -type d -empty -delete
      fi
    done
  '';

  uninstall = pkgs.writeScript "uninstall" ''
    ${unlink}

    if [ -d ${targetDir} ]; then
        echo "removing dotfiles repository" >&2
        rm -rf ${targetDir}
    fi
  '';

  switch = pkgs.writeScript "switch" ''
    set -e

    echo >&2
    echo >&2 "Tagging working config..."

    git branch -f update HEAD

    echo >&2
    echo >&2 "Switching environment..."
    echo >&2

    sudo nixos-rebuild switch

    ${link}

    echo >&2
    echo >&2 "Tagging updated..."
    echo >&2

    git branch -f working update
    git branch -D update
    git push
  '';

  update = pkgs.writeScript "update" ''
    set -e

    echo >&2
    echo >&2 "Updating channels..."
    echo >&2

    nix-channel --update

    ${switch}
  '';
in pkgs.stdenvNoCC.mkDerivation {
  name = "dotfiles";
  preferLocalBuild = true;
  propagatedBuildInputs = [ pkgs.git ];
  propagatedUserEnvPkgs = [ pkgs.git ];

  unpackPhase = ":";

  installPhase = ''
    mkdir -p $out/bin
    echo "$script" > $out/bin/dotfiles
    chmod +x $out/bin/dotfiles
  '';

  script = ''
    set -e

    while [ "$#" -gt 0 ]; do
      i="$1"; shift 1

      case "$i" in
        help)
          echo "dotfiles: [help] [install] [uninstall] [link] [unlink] [switch] [update]"
          exit
          ;;
        link)
          ${link}
          ;;
        switch)
          ${switch}
          ;;
        unlink)
          ${unlink}
          ;;
        uninstall)
          ${uninstall}
          ;;
        update)
          ${update}
          ;;
        *)
          ${install}
          ;;
      esac
    done

    exit
  '';

  passthru.check = pkgs.stdenvNoCC.mkDerivation {
     name = "run-dotfiles-test";
     shellHook = ''
        set -e
        echo >&2 "running dotfiles tests..."
        echo >&2
        echo >&2 "checking repository"
        test -d ${targetDir}
        exit
    '';
  };
}
