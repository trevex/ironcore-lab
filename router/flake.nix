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
      # nixosModules.origin = { config, ... }: {
      #   imports = [
      #     nixos-generators.nixosModules.all-formats
      #   ];

      #   nixpkgs.hostPlatform = "x86_64-linux";

      #   # # customize an existing format
      #   # formatConfigs.vmware = { config, ... }: {
      #   #   services.openssh.enable = true;
      #   # };

      #   # # define a new format
      #   # formatConfigs.my-custom-format = { config, modulesPath, ... }: {
      #   #   imports = [ "${toString modulesPath}/installer/cd-dvd/installation-cd-base.nix" ];
      #   #   formatAttr = "isoImage";
      #   #   fileExtension = ".iso";
      #   #   networking.wireless.networks = {
      #   #     # ...
      #   #   };
      #   # };

      #   # the evaluated machine
      #   nixosConfigurations.origin = nixpkgs.lib.nixosSystem {
      #     modules = [ self.nixosModules.origin ];
      #   };
      # };
      # overlays.default = final: prev: {
      #   prefetched-images = self.packages."x86_64-linux".prefetched-images;
      # };
      packages = forAllSystems ({ system, pkgs }:
      let
        mkIso = modules: nixos-generators.nixosGenerate {
          inherit system;
          modules = [
            # Pin nixpkgs to the flake input, so that the packages installed
            # come from the flake inputs.nixpkgs.url.
            ({ ... }: { nix.registry.nixpkgs.flake = nixpkgs; })
            {
              nixpkgs.pkgs = pkgs;
              system.stateVersion = "23.11";
            }
          ] ++ modules;
          format = "iso";
        };
      in {
        iso = mkIso [ ./configuration.nix ./router.nix ];
      });
    };
}
