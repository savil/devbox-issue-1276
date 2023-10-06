{
  description = "A flake that wraps python310 and autopatchelfs it to the latest libc";

  inputs = {

    # nixpkgs commit of most recent glibc (2.37-8) https://www.nixhub.io/packages/glibc
    nixpkgs-latest.url = "github:nixos/nixpkgs/7131f3c223a2d799568e4b278380cd9dac2b8579";
    
    # from the devbox.lock file for python310@latest
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
