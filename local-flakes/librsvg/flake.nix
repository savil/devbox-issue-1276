{
  description = "A flake that wraps librsvg and autopatchelfs it to the latest libc";

  inputs = {
    # this latest nixpkgs is used for stdenv.cc.cc.lib and similar
    nixpkgs-latest.url = "github:nixos/nixpkgs/3364b5b117f65fe1ce65a3cdd5612a078a3b31e3";

    # this nixpkgs is for librsvg@2.52.5
    nixpkgs-librsvg.url = "github:NixOS/nixpkgs/8eb9d6c0d4d8f744b9c347a5f26c90f5f0e1e830";
    wrapper.url = "github:savil/libc-patcher";
  };

  outputs = { self, nixpkgs-latest, nixpkgs-librsvg, wrapper }:
    let
      system = "x86_64-linux";

      pkgs-latest = (import nixpkgs-latest {
        inherit system;
        config.allowUnfree = true;
      });

      pkgs-librsvg = (import nixpkgs-librsvg {
        # system = "x86_64-linux";
        inherit system;
        config.allowUnfree = true;
      });

      librsvg = wrapper.libcPatcher pkgs-latest "librsvg-patched" pkgs-librsvg.librsvg;

    in {
      packages.${system}.default = librsvg;
    };
}
