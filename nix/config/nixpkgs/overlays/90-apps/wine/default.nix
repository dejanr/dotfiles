{ stdenv, fetchurl, wine, fetchFromGitHub, git, utillinux, autoconf, python3, perl }:

# Latest staging version of Wine
((wine.override {
    wineRelease = "unstable";
    wineBuild = "wineWow";

    cupsSupport = false;
    gphoto2Support = false;
    saneSupport = false;
    openclSupport = false;
    gsmSupport = false;
    gstreamerSupport = false;
    vkd3dSupport = false;
    mingwSupport = true;
}).overrideAttrs (old: rec {
  version = "6.4";

    # From https://github.com/Frogging-Family/wine-tkg-git
    protonPatchRev = "f63bc8e5ea38a29955bd20655c58347a8bdc8158";

    src = fetchFromGitHub {
      owner = "wine-mirror";
      repo = "wine";
      rev = "wine-${version}";
      sha256 = "WaA2ZOkRadzjX8hkQM+NGApMMDEvp0o2nwkDtovTIKk=";
    };

    staging = fetchFromGitHub {
      owner = "wine-staging";
      repo = "wine-staging";
      rev = "v${version}";
      sha256 = "gTt75rRoP/HTeD5k/8bW3jjnn8M5atmP9RFqmBQaAfk=";
    };

    # Temp
    patches = [];

    NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";
    })).overrideDerivation (drv: let
    patch = path: sha256: fetchurl {
      url = "https://raw.githubusercontent.com/Frogging-Family/wine-tkg-git/${drv.protonPatchRev}/wine-tkg-git/wine-tkg-patches/${path}.patch";
      inherit sha256;
    };
  in {
    name = "wine-wow-${drv.version}-staging";

    nativeBuildInputs = drv.nativeBuildInputs ++ [
      git
      perl
      utillinux
      autoconf
      python3
      perl
    ];

    protonPatches = let
      proton = name: patch "proton/${name}";
    in [
      (proton "proton-winevulkan-nofshack" "KkTkoHveGI+Qjjhimz0/vcvX/QPaLUl1e1jz/lRWvBA=")
      (proton "fsync-unix-staging" "k6lreuidDINwN1oNFiK7v3RkNoN26P8x0U2aIfhE0w4=")
      (proton "fsync_futex2" "G+j2oKTWzjGjQqjtKYzRGHOFx12RXUx9WXjabVbt9os=")
    ];

    postPatch =
      let
        vulkanVersion = "1.2.170";

        vkXmlFile = fetchurl {
          name = "vk-${vulkanVersion}.xml";
          url = "https://raw.github.com/KhronosGroup/Vulkan-Docs/v${vulkanVersion}/xml/vk.xml";
          sha256 = "u9nK2kEYliaBED+NSoBFp1LzyQ0BsBJaLpXHDPep890=";
        };
      in ''
        # staging patches
        patchShebangs tools
        cp -r ${drv.staging}/patches .
        chmod +w -R patches/
        cd patches
        patchShebangs gitapply.sh
        ./patchinstall.sh DESTDIR="$PWD/.." --all
        cd ..
        echo "applying Proton patches.."
        for patch in $protonPatches; do
          echo "!! applying ''${patch}"
          patch -Np1 < "$patch"
        done
        # confirm that Wine's vulkan version matches our set one
        localVulkanVersion=$(grep -oP "VK_XML_VERSION = \"\K(.+?)(?=\")" ./dlls/winevulkan/make_vulkan)
        if [ -z "$localVulkanVersion" ]; then
          echo "error: failed to detect Wine Vulkan version"
          exit 1
        fi
        if [[ "$localVulkanVersion" != "${vulkanVersion}" ]]; then
          echo error: detected Wine vulkan version of $localVulkanVersion
          echo .. currently set vulkan version is ${vulkanVersion}
          exit 1
        fi
        patchShebangs ./dlls/winevulkan/make_vulkan
        patchShebangs ./tools/make_requests
        substituteInPlace ./dlls/winevulkan/make_vulkan --replace \
          "vk_xml = \"vk-{0}.xml\".format(VK_XML_VERSION)" \
          "vk_xml = \"${vkXmlFile}\""
        ./dlls/winevulkan/make_vulkan
        ./tools/make_requests
        autoreconf -f
      '';
})

