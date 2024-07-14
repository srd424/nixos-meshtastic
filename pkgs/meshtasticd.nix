{ lib, stdenv
, fetchurl
, autoPatchelfHook
, dpkg
, makeWrapper
, libgpiod_1
#, libyaml-cpp
#, ulfius
, orcania
, openssl
}:

let
  unsupported = throw "unsupported system ${stdenv.hostPlatform.system}";

  srcVariant = {
    x86_64-linux = {
      arch = "amd64";
      hash = lib.fakeHash;
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-4FEyHp8Ie0RNzIbXliTFq7Qw8Dk3hv9vVsYwjbyT+vw=";
    };
    armv7l-linux = {
      arch = "armhf";
      hash = lib.fakeHash;
    };
  }.${stdenv.hostPlatform.system} or unsupported;

in stdenv.mkDerivation (finalAttrs: {
  pname = "meshtasticd";
  version = "2.3.13.83f5ba0";

  src = let
    baseUrl = "https://github.com/meshtastic/firmware/releases/download";
    fileName = "${finalAttrs.pname}_${finalAttrs.version}_${srcVariant.arch}.deb";
  in fetchurl {
    url = "${baseUrl}/v${finalAttrs.version}/${fileName}";
    inherit (srcVariant) hash;
  };

  # https://meshtastic.org/docs/hardware/devices/linux-native-hardware/

  # meshtasticd is compiled on debian bookworm
  # https://github.com/meshtastic/firmware/blob/master/Dockerfile
  # https://packages.debian.org/search?suite=bookworm&keywords=keywords
  buildInputs = [
    libgpiod_1  # nixpkgs: 1.6.4, debian: 1.6.3
    # https://github.com/jbeder/yaml-cpp
    # libyaml-cpp # nixpkgs: -, debian: 0.7.0
    # https://github.com/babelouest/ulfius/blob/master/INSTALL.md
    # ulfius      # nixpkgs: -, debian: 2.7.13
    orcania     # nixpkgs: 2.3.3, debian: 2.3.2
    openssl     # nixpkgs: 3.0.14, debian: 3.0.13
  ];

  nativeBuildInputs = [ autoPatchelfHook dpkg makeWrapper ];

  unpackCmd = "dpkg-deb -x $curSrc source";

  ldLibraryPath = lib.strings.makeLibraryPath finalAttrs.buildInputs;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -r usr/sbin/meshtasticd $out/bin
    cp -r usr/share $out/share

    cp -r etc $out/share
    cp -r usr/lib $out/share

    # for file in $out/bin/*; do
    #   chmod +w $file
    #   patchelf --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" \
    #           --set-rpath ${lib.makeLibraryPath [ stdenv.cc.cc ]} \
    #           $file
    # done

    runHook postInstall
  '';

  postFixup = ''
    # find $out -type f -executable | \
    # while IFS= read -r f ; do
    #   patchelf --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" $f
    #   wrapProgram $f \
    #     "''${gappsWrapperArgs[@]}" \
    #     --prefix LD_LIBRARY_PATH : "${finalAttrs.ldLibraryPath}" \
    #     --prefix PATH : "${lib.makeBinPath [ libgpiod_1 ]}"
    # done
  '';

  meta = with lib; {
    description = "Meshtastic device firmware for Linux-native devices (meshtasticd)";
    longDescription = ''
      meshtasticd is a Meshtastic daemon for Linux-native devices, utilizing
      portduino to run the firmware under Linux.
    '';
    homepage = "https://github.com/meshtastic/firmware";
    changelog = "https://github.com/meshtastic/firmware/releases/tag/v${finalAttrs.version}";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" "aarch64-linux" "armv7l-linux" ];
    maintainers = with maintainers; [ kazenyuk ];
  };
})