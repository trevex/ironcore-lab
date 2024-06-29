{ flake, inputs, lib, pkgs, config,  ... }:
let
  # NOTE: an alternative not using a raw image would be https://discourse.nixos.org/t/nixos-automatic-unattended-offline-installer-usb-stick/6114/2:w
  # TODO: do not use hardcoded system, instead builtin.currentSystem?
  install-router-to-disk = pkgs.writeShellScriptBin "install-router-to-disk"
    ''
    #!/usr/bin/env bash
    set -euxo pipefail
    dd if=${flake.nixosConfigurations.router.config.formats.raw-efi} of=$1 bs=64K conv=noerror,sync
    '';
in
{

  defaultUser = "installer";

  # TODO: can also be systemd service for unattended install, see link above...
  environment.systemPackages = with pkgs; [
    install-router-to-disk
    # some utility packages to debug things...
    gptfdisk
    vim
    git
    ripgrep
    curl
    moreutils
    unzip
    htop
    fd
    dig
    openssl
    tcpdump
    inetutils
  ];
}
