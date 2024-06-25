{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, ... }:
    let
      allSystems = [ "x86_64-linux" ]; # "aarch64-linux"
      mkPkgs = system:  pkgs: overlays: import pkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = overlays;
      };
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        inherit system;
        pkgs = mkPkgs system nixpkgs [
          (final: prev: {
            images = self.packages."${system}";
          })
        ];
      });
    in
    {
      packages = forAllSystems ({ system, pkgs }:
      let
        mkFormat = format: vars: modules: nixos-generators.nixosGenerate {
          inherit system format;
          specialArgs = { inherit vars; flake = self; };
          modules = [
            # Pin nixpkgs to the flake input, so that the packages installed
            # come from the flake inputs.nixpkgs.url.
            ({ ... }: { nix.registry.nixpkgs.flake = nixpkgs; })
            {
              nixpkgs.pkgs = pkgs;
              system.stateVersion = "23.11";
            }
          ] ++ modules;
        };
      in {
        router-vm-iso = mkFormat "iso" { externalInterface = "ens3"; internalInterface = "ens4"; } [ ./configuration.nix ./router.nix ];
        router-hw-raw = mkFormat "raw-efi" { externalInterface = "enp1s0"; internalInterface = "enp3s0"; } [ ./configuration.nix ./router.nix ./raw-tweaks.nix ./openssh.nix ./wireguard.nix ];
        install-hw-iso = mkFormat "iso" {} [ ./configuration.nix ./install.nix ];
      });
    };
}
