source $stdenv/setup

build_dxvk() {
    echo "building ${1}-bit version of DXVK"

    _configure_dxvk $1
    _compile_dxvk $1
    _install_dxvk $1

    echo "finished building ${1}-bit version of DXVK"
}

_configure_dxvk() {
    meson \
        --cross-file build-wine${1}.txt \
        --buildtype release \
        --prefix $PWD/build${1} \
        --strip \
        build.wine${1}
}

_compile_dxvk() {
    cd build.wine${1}
    ninja install
    cd ..
}

_install_dxvk() {
    local lib_dir=$out/share/dxvk/

    if [ $1 == 64 ]; then
        lib_dir=$lib_dir/x64
    else
        lib_dir=$lib_dir/x32
    fi

    mkdir -p $lib_dir

    cd build${1}

    cp lib/dxgi.dll.so $lib_dir/dxgi.dll
    cp lib/d3d11.dll.so $lib_dir/d3d11.dll
    cp lib/d3d10.dll.so $lib_dir/d3d10.dll
    cp lib/d3d10core.dll.so $lib_dir/d3d10core.dll
    cp lib/d3d10_1.dll.so $lib_dir/d3d10_1.dll

    cd ..
}
