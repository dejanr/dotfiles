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
    gstreamerSupport = false;
    mingwSupport = true;
  }).overrideAttrs (oldAttrs: rec {
    version = "6.20";

    protonGeVersion = "GE-1";

    fullVersion = "${version}-${protonGeVersion}";

    src = super.fetchFromGitHub {
      owner = "wine-mirror";
      repo = "wine";
      rev = "wine-${version}";
      sha256 = "9aDK4lXaId+q2zAQNEwfKNBRhfkpfar8J37WG9JPENE=";
    };

    staging = super.fetchFromGitHub {
      owner = "wine-staging";
      repo = "wine-staging";
      rev = "v${version}";
      sha256 = "dlF5ufIGF2Qh/OGiusjANCAmE8DUxz7zbRzrfI5124k=";
    };

    NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";
  })).overrideDerivation (drv: let
    patch = path: sha256: super.fetchurl {
      url = "https://raw.githubusercontent.com/GloriousEggroll/proton-ge-custom/${drv.version}-${drv.protonGeVersion}/patches/${path}.patch";
      inherit sha256;
    };

    proton = name: patch "proton/${name}";
    hotfix = name: patch "wine-hotfixes/${name}";
  in {
    name = "wine-wow-${drv.version}-staging";

    nativeBuildInputs = drv.nativeBuildInputs ++ [
      super.git
      super.perl
      super.autoconf
      super.python3
    ];

    protonPatches = [
      (proton "01-proton-use_clock_monotonic" "EM502UOkslyXNLT9w1Paj/cLSpHeACZJn7HJqRjgxuk=")
      (proton "03-proton-fsync_staging" "BFcs1y1B1o/A/iybEgR6P6kiFaMrPJkZL49t5sJIzW4=")
      (proton "04-proton-LAA_staging" "nahqJ/PjFXAv9dV3HlJeDIchsiNPAkRW2WCFWQfDSBE=")
      (proton "08-proton-steamclient_swap" "58LZZxRNgWyvZX/j8bbZGhmS+IZ+WIA9eaKDBAHdwjg=")
      #(proton "10-proton-protonify_staging" "FzxaRjyB6SmcTvJuLuJ5TG2Phzk4UKgPp6c9/b5oMpk=")
      ./patches/wine_protonify.patch # Same as above but without a few winhttp patches that cause errors
      (proton "18-proton-amd_ags" "qk89nt1Ni67EBWT2w8oprG7Co+/jOdlmzC8F73xn9s0=")
      (proton "40-proton-futex2" "G+j2oKTWzjGjQqjtKYzRGHOFx12RXUx9WXjabVbt9os=")
      # broken
      #(proton "41-valve_proton_fullscreen_hack-staging-tkg" "YECgZgtWvZOpGWIGlGiwKCpehUpI9CNSqjX1ZinwPEs=")
      #(proton "48-proton-fshack_amd_fsr" "kC7VHAC830aCfF1HXnwMm9j2jd2oQjFjTzfpqg0r4Qs=")
      (proton "49-proton_QPC" "+4tkY+hpRf5KJN6Ggx/95Oz7LjY76SXoiEkrpxxGWco=")
      (proton "50-proton_LFH" "X0MmPblcRj2LApUvsBaLtGSV/gvUE/dsuEfmMNZ4ApU=")
      (proton "51-proton_fonts" "RAYMMYaVW8uEXCqbZgWuWjLkY+RCBdJlS7W8+SoZ1Yk=")

      (hotfix "pending/hotfix-remi_heap_alloc" "iOu0ulDghiAeOFB9Ab9i4S0TC2GSVuToAphbXbrFVP8=")
    ];

    reverts = [
      (hotfix "steamclient/d4259ac8e93_revert" "B3GuY52ufzhDdkNCwWzFKRW3QupA4GRuXdu8V8PvXsM=")
      "patches/Compiler_Warnings/0031-include-Check-element-type-in-CONTAINING_RECORD-and-.patch"
    ];

    preStagingReverts = [
      (hotfix "staging/proton-staging-syscall-emu" "/mN70WxCjX1bxNn9iqXzlTJ7Wj9DxwNf1O92xTa0A08=")
    ];

    postPatch =
      let
        vulkanVersion = "1.2.196";

        vkXmlFile = super.fetchurl {
          name = "vk-${vulkanVersion}.xml";
          url = "https://raw.github.com/KhronosGroup/Vulkan-Docs/v${vulkanVersion}/xml/vk.xml";
          sha256 = "fAumeM5F9vldZvbHD+k0RzNRS8GiUHAJZk+I/BAOW9Y=";
        };
      in ''
        # staging patches
        patchShebangs tools
        cp -r ${drv.staging}/patches .
        chmod +w -R patches/

        for patch in $preStagingReverts; do
          echo "!! reverting pre-staging ''${patch}"
          patch -Np1 < "$patch"
        done

        cd patches
        patchShebangs gitapply.sh
        ./patchinstall.sh DESTDIR="$PWD/.." --all \
          -W winex11-_NET_ACTIVE_WINDOW \
          -W winex11-WM_WINDOWPOSCHANGING \
          -W ntdll-NtAlertThreadByThreadId \
          -W dwrite-FontFallback
        cd ..

        echo "applying reverts.."

        for patch in $reverts; do
          echo "!! reverting ''${patch}"
          patch -RNp1 < "$patch"
        done

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
