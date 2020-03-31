{ pkgs ? (import ./nix).pkgs {}
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

  switch = pkgs.writeScript "switch" ''
    #! /usr/bin/env bash
    set -o pipefail -o noclobber -o nounset

    function error() {
        local red
        local reset
        red="$(tput setaf 1)"
        reset="$(tput sgr0)"

        printf "%s%s%s\n" "$red" "$*" "$reset"
        exit 1
    }

    function set_work_dir() {
        if [[ ! -v WORK_DIR ]]; then
            WORK_DIR="$(mktemp --tmpdir -u nix-config-sync.XXXXXXXXXX)"
            trap "rm -rf '$WORK_DIR'" EXIT
        fi
    }

    function build() {
        [ "$#" -eq 0 ] || error "build"
        set_work_dir
        local machine
        machine="$(hostname)"
        unset NIX_PATH
        nix-build machines.nix --out-link "$WORK_DIR" -A "$machine" ||
            error "Failed to build system"
    }

    function switch() {
        [ "$#" -eq 0 ] || error "switch"
        set_work_dir
        local switch_bin="$WORK_DIR/bin/switch-to-configuration"
        sudo nix-env --set \
            --profile "/nix/var/nix/profiles/system" \
            "$WORK_DIR" ||
            error "Failed to activate profile"
        sudo "$switch_bin" "switch" ||
            error "Failed to activate system"
    }

    function main() {
        build
        switch
        exit 0
    }

    main "$@"
  '';

  help = pkgs.writeScript "help" ''
    #!/usr/bin/env bash
    echo "usage: dotfiles <command>"
    echo ""
    echo "  link    Symlink all dotfiles"
    echo "  unlink  Remove all symlinked dotfiles"
    echo "  switch  Remove all symlinked dotfiles"
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
    option=''${1:-help}
    case $option in
      link      ) ${link} ;;
      unlink    ) ${unlink} ;;
      switch    ) ${switch} ;;
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
