{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs {}
, dotfilesDir ? "$HOME/.dotfiles"
}:

let
  link = pkgs.writeScript "link" ''
    #!/usr/bin/env bash
    set -e

    link() {
      from="$1"
      to="$2"
      echo "link $from -> $to"
      rm -f $to
      ln -s "$from" "$to"
    }

    mkdir -p ~/.config

    for main in $(find ${dotfilesDir} -maxdepth 2 -mindepth 2 ! -path '*.git*' | sort)
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
    #!/usr/bin/env bash
    set -e

    remove() {
      from="$1"
      echo "unlink $from"
      unlink $from
    }

    for main in $(find ${dotfilesDir} -maxdepth 2 -mindepth 1 ! -path '*.git*' | sort -r)
    do
      name=$(basename $main)

      if [ -L $HOME/.$name ]; then
        remove $HOME/.$name
      fi

      if [ -d $HOME/.$name ]; then
        for location in $(find $main -maxdepth 1 -mindepth 1)
        do
          dot=$(basename $location)

          if [ -L $HOME/.$name/$dot ]; then
            remove $HOME/.$name/$dot
          fi
        done

        echo "rmdir $HOME/.$name"
        find $HOME/.$name -type d -empty -delete
      fi
    done
  '';

  help = pkgs.writeScript "help" ''
    #!/usr/bin/env bash
    echo "usage: dotfiles <command>"
    echo ""
    echo "  link    Symlink all dotfiles"
    echo "  unlink  Remove all symlinked dotfiles"
    exit
  '';
in
pkgs.stdenv.mkDerivation {
  name = "dotfiles";
  preferLocalBuild = true;
  propagatedBuildInputs = [ pkgs.git ];
  propagatedUserEnvPkgs = [ pkgs.git ];

  unpackPhase = ":";

  script = ''
    set -e
    option=''${1:-help}
    case $option in
      link      ) ${link} ;;
      unlink    ) ${unlink} ;;
      help      ) ${help} ;;
      *         ) ${help} && exit 1 ;;
    esac
    exit
  '';

  installPhase = ''
    mkdir -p $out/bin
    echo "$script" > $out/bin/dotfiles
    chmod +x $out/bin/dotfiles
  '';
}
