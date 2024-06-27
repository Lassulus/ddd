{
  description = "distributed data daemon for exchanging data (like hostnames) in distributed networks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }: {
      imports = [ ./treefmt.nix ];
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "riscv64-linux"

        "x86_64-darwin"
        "aarch64-darwin"
      ];
      flake.checks.x86_64-linux.data-mesher = import ./tests/nixos_tests/default.nix { inherit lib; pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux; };
      perSystem = { config, pkgs, self', ... }: {
        packages.data-mesher = pkgs.callPackage ./. { };
        packages.default = config.packages.data-mesher;
        devShells.default = self'.packages.default.overrideAttrs (old: {
          nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.python3Packages.ipython ];
          # propagatedBuildInputs = old.propagatedBuildInputs ++ [ pkgs.python3Packages.ipython ];
        });

        checks =
          let
            packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self'.packages;
            devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self'.devShells;
          in
          packages // devShells;
      };
      flake.nixosModules.data-mesher = {
        imports = [ ./module.nix ];
      };
    });
}
