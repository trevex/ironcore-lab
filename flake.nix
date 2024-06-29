{
  description = "ironcore-lab";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    let
      overlays = [ ];
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system overlays; };
      in
      rec {
        devShell = pkgs.mkShell rec {
          name = "ironcore-lab";

          buildInputs = with pkgs; [
            curl
            gnugrep
            gnused
            gnumake

            qemu
            opentofu
            libxslt # required for libvirt provider

            tcpdump
            wireshark
            wireguard-tools

            deploy-rs

            kubectl
            kubernetes-helm
            kind
            kubevirt
            clusterctl
            talosctl
          ];
        };
      }
    );
}
