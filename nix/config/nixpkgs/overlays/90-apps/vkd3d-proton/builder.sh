source $stdenv/setup

build_vkd3d() {
    echo "building ${1}-bit version of VKD3D-Proton"

    _configure $1
    _compile $1
    _install $1

    echo "finished building ${1}-bit version of VKD3D-Proton"
}

_configure() {
    meson \
        --cross-file build-win${1}.txt \
        --buildtype release \
        --prefix $PWD/build${1} \
        --strip \
        build.wine${1}
}

_compile() {
    ninja -C build.wine${1} install
}

_install() {
    local lib_dir=$out/bin/

    if [ $1 == 64 ]; then
        lib_dir=$lib_dir/x64
    else
        lib_dir=$lib_dir/x86
    fi

    mkdir -p $lib_dir
    cp build${1}/bin/*.dll $lib_dir/
}
