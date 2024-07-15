{ lib, stdenv
, fetchFromGitHub
, fetchpatch
, cmake
}:

# https://github.com/NixOS/nixpkgs/tree/nixos-22.11/pkgs/development/libraries/libyaml-cpp
stdenv.mkDerivation (finalAttrs: {
  pname = "yaml-cpp";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "jbeder";
    repo  = "yaml-cpp";
    rev   = "yaml-cpp-${finalAttrs.version}";
    hash  = "sha256-2tFWccifn0c2lU/U1WNg2FHrBohjx8CXMllPJCevaNk=";
  };

  patches = [
    # https://github.com/jbeder/yaml-cpp/issues/774
    # https://github.com/jbeder/yaml-cpp/pull/1037
    (fetchpatch {
      url = "https://github.com/jbeder/yaml-cpp/commit/4f48727b365962e31451cd91027bd797bc7d2ee7.patch";
      sha256 = "sha256-jarZAh7NgwL3xXzxijDiAQmC/EC2WYfNMkYHEIQBPhM=";
    })
    # TODO: Remove with the next release, when https://github.com/jbeder/yaml-cpp/pull/1058 is available
    (fetchpatch {
      name = "libyaml-cpp-Fix-pc-paths-for-absolute-GNUInstallDirs.patch";
      url = "https://github.com/jbeder/yaml-cpp/commit/328d2d85e833be7cb5a0ab246cc3f5d7e16fc67a.patch";
      sha256 = "12g5h7lxzd5v16ykay03zww5g28j3k69k228yr3v8fnmyv2spkfl";
    })
  ];

  nativeBuildInputs = [ cmake ];

  # more patching: same as the second patch above, but for gmock and gtest
  postPatch = ''
    substituteInPlace test/gtest-1.10.0/googlemock/cmake/gmock.pc.in \
      --replace-warn "\''${prefix}/@CMAKE_INSTALL_INCLUDEDIR@" "@CMAKE_INSTALL_FULL_INCLUDEDIR@"
    substituteInPlace test/gtest-1.10.0/googlemock/cmake/gmock.pc.in \
      --replace-warn "\''${prefix}/@CMAKE_INSTALL_LIBDIR@" "@CMAKE_INSTALL_FULL_LIBDIR@"

    substituteInPlace test/gtest-1.10.0/googlemock/cmake/gmock_main.pc.in \
      --replace-warn "\''${prefix}/@CMAKE_INSTALL_INCLUDEDIR@" "@CMAKE_INSTALL_FULL_INCLUDEDIR@"
    substituteInPlace test/gtest-1.10.0/googlemock/cmake/gmock_main.pc.in \
      --replace-warn "\''${prefix}/@CMAKE_INSTALL_LIBDIR@" "@CMAKE_INSTALL_FULL_LIBDIR@"

    substituteInPlace test/gtest-1.10.0/googletest/cmake/gtest.pc.in \
      --replace-warn "\''${prefix}/@CMAKE_INSTALL_INCLUDEDIR@" "@CMAKE_INSTALL_FULL_INCLUDEDIR@"
    substituteInPlace test/gtest-1.10.0/googletest/cmake/gtest.pc.in \
      --replace-warn "\''${prefix}/@CMAKE_INSTALL_LIBDIR@" "@CMAKE_INSTALL_FULL_LIBDIR@"

    substituteInPlace test/gtest-1.10.0/googletest/cmake/gtest_main.pc.in \
      --replace-warn "\''${prefix}/@CMAKE_INSTALL_INCLUDEDIR@" "@CMAKE_INSTALL_FULL_INCLUDEDIR@"
    substituteInPlace test/gtest-1.10.0/googletest/cmake/gtest_main.pc.in \
      --replace-warn "\''${prefix}/@CMAKE_INSTALL_LIBDIR@" "@CMAKE_INSTALL_FULL_LIBDIR@"
  '';

  doCheck = true;

  cmakeFlags = [
    "-DYAML_BUILD_SHARED_LIBS=on"
  ] ++ lib.optional finalAttrs.doCheck [
    "-DYAML_CPP_BUILD_TESTS=on"
  ];

  meta = with lib; {
    description = "A YAML parser and emitter in C++ matching the YAML 1.2 spec";
    homepage = "https://github.com/jbeder/yaml-cpp";
    changelog = "https://github.com/jbeder/yaml-cpp/releases/tag/yaml-cpp-${finalAttrs.version}";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ kazenyuk ];
  };
})