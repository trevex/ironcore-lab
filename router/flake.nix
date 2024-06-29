{
  inputs = {
    nixpkgs.url = "nixpkgs/24.05";
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs.url = "github:serokell/deploy-rs";
  };
  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, nixos-generators, deploy-rs, ... }:
  let
    system = "x86_64-linux";
    vars = {
      defaultUser = "router";
      externalInterface = "";
      externalIP = "";
      internalInterface = "";
      internalIP = "";
      nat64 = {
        tunDevice = "nat64";
      };
    };

    mkPkgs = pkgs: overlays: import pkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = overlays;
    };
    pkgs = mkPkgs nixpkgs (lib.attrValues self.overlays);
    pkgs' = mkPkgs nixpkgs-unstable [ ];

    overlay =
      final: prev: {
        unstable = pkgs';
      };

    lib = nixpkgs.lib;

    mkHost = hostModules: lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs system; flake = self; };

      modules = [
        {
          imports = [
            nixos-generators.nixosModules.all-formats
            ./modules/default-user.nix
            ./modules/hardware-configuration.nix
            ./modules/router.nix
          ];
          nixpkgs.pkgs = pkgs;
          system.stateVersion = "24.05";
          nix = {
            package = pkgs.nixFlakes;
            extraOptions = "experimental-features = nix-command flakes";
            settings = {
              allowed-users = [ "@wheel" ];
              trusted-users = [ "@wheel" ];
            };
          };

          formatConfigs.raw-efi = { config, ... }: {
            hardwareConfiguration.enable = false;
          };

          formatConfigs.iso = { config, ... }: {
            hardwareConfiguration.enable = false;
          };
        }
      ] ++ (lib.lists.forEach hostModules (hm: import hm));
    };
  in {
    overlays.default = overlay;

    nixosConfigurations = {
      router = mkHost [ ./router.nix ];
      installer = mkHost [ ./installer.nix ];
    };

    deploy.nodes.router = {
      hostname = "192.168.1.131";
      profiles.system = {
        user = "root";
        remoteBuild = true;
        sshUser = "test";
        magicRollback = false;
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.router;
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
