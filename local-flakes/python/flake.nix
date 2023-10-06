{
  description = "A flake that wraps python310 and autopatchelfs it to the latest libc";

  inputs = {
    nixpkgs-latest.url = "github:nixos/nixpkgs/3364b5b117f65fe1ce65a3cdd5612a078a3b31e3";
    nixpkgs-python.url = "github:nixos/nixpkgs/806075be2bdde71895359ed18cb530c4d323e6f6";
    wrapper.url = "github:savil/libc-patcher";
  };

  outputs = { self, nixpkgs-latest, nixpkgs-python, wrapper }:
    let
      system = "x86_64-linux";
      pkgs-latest = (import nixpkgs-latest {
        inherit system;
        config.allowUnfree = true;
      });
      pkgs-python = (import nixpkgs-python {
        inherit system;
        config.allowUnfree = true;
      });

      python3 = wrapper.libcPatcher pkgs-latest "python-patched" pkgs-python.python3;

    in {
      packages.${system}.default = python3;
    };
}
