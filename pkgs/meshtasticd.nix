{ lib, stdenv
, fetchurl
, autoPatchelfHook
, dpkg
, libgpiod_1
, libyaml-cpp
, ulfius
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
      hash = "sha256-PLRSBX0bT2hb+HODHRi8Te3FpFRof2eAqH6WilZoXYQ=";
    };
    armv7l-linux = {
      arch = "armhf";
      hash = lib.fakeHash;
    };
  }.${stdenv.hostPlatform.system} or unsupported;

in stdenv.mkDerivation (finalAttrs: {
  pname = "meshtasticd";
  version = "2.4.1.394e0e1";

  src = let
    baseUrl = "https://github.com/meshtastic/firmware/releases/download";
    fileName = "${finalAttrs.pname}_${finalAttrs.version}_${srcVariant.arch}.deb";
  in fetchurl {
    url = "${baseUrl}/v${finalAttrs.version}/${fileName}";
    inherit (srcVariant) hash;
  };

  nativeBuildInputs = [ autoPatchelfHook dpkg ];

  unpackCmd = "dpkg-deb -x $curSrc source";

  # meshtasticd is compiled on debian bookworm
  # https://github.com/meshtastic/firmware/blob/master/Dockerfile
  # https://packages.debian.org/search?suite=bookworm&keywords=keywords
  buildInputs = [
    libgpiod_1  # nixpkgs: 1.6.4, debian: 1.6.3
    libyaml-cpp # nixpkgs: -, debian: 0.7.0
    ulfius      # nixpkgs: -, debian: 2.7.13
    orcania     # nixpkgs: 2.3.3, debian: 2.3.2
    openssl     # nixpkgs: 3.0.14, debian: 3.0.13
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -r usr/sbin/meshtasticd $out/bin
    cp -r usr/share $out/share

    cp -r etc $out/share
    cp -r usr/lib $out/share

    runHook postInstall
  '';

  meta = with lib; {
    description = "Meshtastic device firmware for Linux-native devices (meshtasticd)";
    longDescription = ''
      meshtasticd is a Meshtastic daemon for Linux-native devices, utilizing
      portduino to run the firmware under Linux.
      https://meshtastic.org/docs/hardware/devices/linux-native-hardware/
    '';
    homepage = "https://github.com/meshtastic/firmware";
    changelog = "https://github.com/meshtastic/firmware/releases/tag/v${finalAttrs.version}";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" "aarch64-linux" "armv7l-linux" ];
    maintainers = with maintainers; [ kazenyuk ];
  };
})