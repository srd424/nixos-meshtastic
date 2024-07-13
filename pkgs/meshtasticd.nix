{ lib, stdenv
, fetchFromGitHub
, pkg-config
, python3
, platformio
# , platformio-core
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "meshtasticd";
  version = "2.3.13.83f5ba0";

  src = fetchFromGitHub {
    owner = "meshtastic";
    repo = "firmware";
    rev = "v${finalAttrs.version}";
    hash = "sha256-m2O1imLZs0IfeaRqiGbgOzh5kwPktivWGfQrjFUhMdM=";
    fetchSubmodules = true;
  };

  # https://github.com/meshtastic/firmware/blob/master/Dockerfile
  # https://meshtastic.org/docs/hardware/devices/linux-native-hardware/

  nativeBuildInputs = [ pkg-config python3 platformio ];
  patchPhase = ''
    substituteInPlace bin/build-native.sh \
      --replace-warn "$(uname -m)" "${stdenv.targetPlatform.uname.processor}"
  '';
  buildPhase = ''
    # source ./bin/activate # from venv
    bash ./bin/build-native.sh
  '';

  meta = with lib; {
    description = "Meshtastic device firmware for Linux-native devices (meshtasticd)";
    longDescription = ''
      meshtasticd is a Meshtastic daemon for Linux-native devices, utilizing
      portduino to run the firmware under Linux.
    '';
    homepage = "https://github.com/meshtastic/firmware";
    changelog = "https://github.com/meshtastic/firmware/releases/tag/v${finalAttrs.version}";
    license = licenses.gpl3Only;
    platforms = [ "aarch64-linux" "x86_64-linux" ];
    maintainers = with maintainers; [ kazenyuk ];
  };
})