{
  description = "Background for the COSMIC desktop environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nix-filter, crane, fenix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # Use latest Rust toolchain for 2024 edition support
        craneLib = (crane.mkLib pkgs).overrideToolchain fenix.packages.${system}.latest.toolchain;
        pkgDef = {
          src = nix-filter.lib.filter {
            root = ./.;
            exclude = [
              ./.gitignore
              ./flake.nix
              ./flake.lock
              ./LICENSE
              ./debian
            ];
          };
          nativeBuildInputs = with pkgs; [
            just
            pkg-config
          ];
          buildInputs = with pkgs; [
            wayland
            libxkbcommon
            desktop-file-utils
            # GStreamer for video wallpaper support
            gst_all_1.gstreamer
            gst_all_1.gst-plugins-base
            gst_all_1.gst-plugins-good
            gst_all_1.gst-plugins-bad
            gst_all_1.gst-plugins-ugly
            gst_all_1.gst-libav
            # Hardware acceleration support
            libva
          ];
        };

        cargoArtifacts = craneLib.buildDepsOnly pkgDef;
        cosmic-bg = craneLib.buildPackage (pkgDef // {
          inherit cargoArtifacts;
        });
      in {
        checks = {
          inherit cosmic-bg;
        };

        packages.default = cosmic-bg;

        apps.default = flake-utils.lib.mkApp {
          drv = cosmic-bg;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = builtins.attrValues self.checks.${system};
        };
      });

  nixConfig = {
    # Cache for the Rust toolchain in fenix
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };
}
