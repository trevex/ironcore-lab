{ flake, inputs, lib, pkgs, config,  ... }:
let
  install-router-to-disk = pkgs.writeShellScriptBin "install-router-to-disk"
    ''
    #!/usr/bin/env bash
    set -euxo pipefail
    dd if=${flake.packages.x86_64-linux.router-raw}/nixos.img of=$1 bs=64K conv=noerror,sync
    '';
in
{
  environment.systemPackages = with pkgs; [
    install-router-to-disk
  ];
}
