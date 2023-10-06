{
  description = "A flake that wraps pip and autopatchelfs it to the latest libc";

  inputs = {
    nixpkgs-latest.url = "github:nixos/nixpkgs/3364b5b117f65fe1ce65a3cdd5612a078a3b31e3";
    nixpkgs-pip.url = "github:nixos/nixpkgs/806075be2bdde71895359ed18cb530c4d323e6f6";
    wrapper.url = "github:savil/libc-patcher";
  };

  outputs = { self, nixpkgs-latest, nixpkgs-pip, wrapper }:
    let
      system = "x86_64-linux";
      pkgs-latest = (import nixpkgs-latest {
        inherit system;
        config.allowUnfree = true;
      });
      pkgs-pip = (import nixpkgs-pip {
        inherit system;
        config.allowUnfree = true;
      });

      pip = wrapper.libcPatcher pkgs-latest "pip-patched" pkgs-pip.python310Packages.pip;
    in {
      packages.${system}.default = pip;
    };
}
