{
  description = "Nexus Flutter Flake";

  inputs = {
    self.submodules = true;
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix2flatpak.url = "github:neobrain/nix2flatpak";
  };

  outputs =
    {
      flake-parts,
      nixpkgs,
      self,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem =
        {
          lib,
          pkgs,
          system,
          ...
        }:

        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config = {
              android_sdk.accept_license = true;
              allowUnfree = true;
            };
          };

          devShells.default = pkgs.callPackage ./linux/nix/devshell.nix { };
        };
    };
}
