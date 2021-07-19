self: super:

{
  # Latest Wine staging with select patches from wine-tkg-git (https://github.com/Frogging-Family/wine-tkg-git).
  wine = ((super.wine.override {
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
  }).overrideAttrs (oldAttrs: rec {
    version = "6.12";

    # From https://github.com/Frogging-Family/wine-tkg-git
    protonPatchRev = "cdc194ab1d4e65979ac45c8632b687c46f4ade99";

    src = super.fetchFromGitHub {
      owner = "wine-mirror";
      repo = "wine";
      rev = "wine-${version}";
      sha256 = "KXl8T6ZamYh9pVvq9sD3i+OyJtTW9wt0hU0o/NiRRzk=";
    };

    staging = super.fetchFromGitHub {
      owner = "wine-staging";
      repo = "wine-staging";
      #rev = "v${version}";
      rev = "163f74fe61851ff57264437073805dd5e7afe2bd";
      sha256 = "92718RI3eRd5Sf6GWqk5mQaQVRwMs5puW1ZMWXj25dU=";
    };

    # Temp
    patches = [];

    NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";
  })).overrideDerivation (drv: let
    patch = path: sha256: super.fetchurl {
      url = "https://raw.githubusercontent.com/Frogging-Family/wine-tkg-git/${drv.protonPatchRev}/wine-tkg-git/wine-tkg-patches/${path}.patch";
      inherit sha256;
    };
  in {
    name = "wine-wow-${drv.version}-staging";

    nativeBuildInputs = drv.nativeBuildInputs ++ [
      super.git
      super.perl
      super.utillinux
      super.autoconf
      super.python3
      super.perl
    ];

    protonPatches = let
      proton = name: patch "proton/${name}";
    in [
      #(proton "proton-winevulkan-nofshack" "h44pBXCZ5pxepHpgNubnNwJy2JHzDlgbruqPlJ0OnVw=")
      (proton "fsync-unix-staging" "UIZNHmR41s7UamsDFJZy9s0gYrRpSRnAkriL2O2vODo=")
      (proton "fsync_futex2" "G+j2oKTWzjGjQqjtKYzRGHOFx12RXUx9WXjabVbt9os=")
    ];

    postPatch =
      let
        vulkanVersion = "1.2.182";

        vkXmlFile = super.fetchurl {
          name = "vk-${vulkanVersion}.xml";
          url = "https://raw.github.com/KhronosGroup/Vulkan-Docs/v${vulkanVersion}/xml/vk.xml";
          sha256 = "dxhxE4rB9CujFQGXqffC5E4Is8Z6jY6KNnTIbkBVydQ=";
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
    });
  }
