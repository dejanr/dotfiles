source $stdenv/setup

build_d9vk() {
    echo "building ${1}-bit version of D9VK"

    _configure_d9vk $1
    _compile_d9vk $1
    _install_d9vk $1

    echo "finished building ${1}-bit version of D9VK"
}

_configure_d9vk() {
    meson \
        --cross-file build-wine${1}.txt \
        --buildtype release \
        --prefix $PWD/build${1} \
        --strip \
        -Denable_d3d11=false \
        -Denable_d3d10=false \
        -Denable_dxgi=false \
        build.wine${1}
}

_compile_d9vk() {
    cd build.wine${1}
    ninja install
    cd ..
}

_install_d9vk() {
    local lib_dir=$out/share/d9vk/

    if [ $1 == 64 ]; then
        lib_dir=$lib_dir/x64
    else
        lib_dir=$lib_dir/x32
    fi

    mkdir -p $lib_dir

    cd build${1}
    cp lib/d3d9.dll.so $lib_dir/d3d9.dll
    cd ..
}
