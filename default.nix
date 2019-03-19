{ pkgs ? import <nixpkgs> {}
, repoUrl ? "git@github.com:dejanr/dotfiles.git"
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
      echo "link $from -> $to"
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

    remove() {
      from="$1"
      echo "unlink $from"
      unlink $from
    }

    for main in $(find ${targetDir} -maxdepth 2 -mindepth 1 ! -path '*.git*' | sort -r)
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

  uninstall = pkgs.writeScript "uninstall" ''
    ${unlink}

    if [ -d ${targetDir} ]; then
        echo "removing dotfiles repository" >&2
        rm -rf ${targetDir}
    fi
  '';

  help = pkgs.writeScript "help" ''
    echo "dotfiles: [install] [uninstall] [link] [unlink] [help]"
    exit
  '';

in pkgs.stdenv.mkDerivation {
  name = "dotfiles";
  preferLocalBuild = true;
  propagatedBuildInputs = [ pkgs.git ];
  propagatedUserEnvPkgs = [ pkgs.git ];

  unpackPhase = ":";

  script = ''
    set -e
    while [ "$#" -gt 0 ]; do
      case "$1" in
        install   ) ${install} ;;
        uninstall ) ${uninstall} ;;
        link      ) ${link} ;;
        unlink    ) ${unlink} ;;
        *         ) ${help} ;;
      esac
      shift 1
    done
    exit
  '';

  installPhase = ''
    mkdir -p $out/bin
    echo "$script" > $out/bin/dotfiles
    chmod +x $out/bin/dotfiles
  '';
}
