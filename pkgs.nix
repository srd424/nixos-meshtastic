{ self, flake-utils, nixpkgs, ... }:


flake-utils.lib.eachDefaultSystem (system: let
  pkgs = nixpkgs.legacyPackages.${system};
in {
  packages = {
    libyaml-cpp = pkgs.callPackage ./pkgs/libyaml-cpp.nix {};
    ulfius = pkgs.callPackage ./pkgs/ulfius.nix {};
    meshtasticd = pkgs.callPackage ./pkgs/meshtasticd.nix {
      inherit (self.packages.${system}) libyaml-cpp ulfius;
    };
  };
})