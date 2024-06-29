{ lib, pkgs, config, ... }:
{
  # Tweak to use correct tty
  boot.kernelParams = [ "console=tty0" ];

  # NOTE: The following would be required if testing install process in a VM:
  # boot.initrd.kernelModules = [
  #   "virtio_blk"
  #   "virtio_pmem"
  #   "virtio_console"
  #   "virtio_pci"
  #   "virtio_mmio"
  # ];

  defaultUser = "test";

  router = {
    enable = true;
    externalInterface = "enp1s0";
    internalInterface = "enp3s0";
    internalAddress = "fd00:cafe::2";
    openssh = {
      enable = true;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGcKW01TP/gVI1KaExyrOMnnj7HUQ58Pa40r4nKGVQ8f niklas.voss@gmail.com"
      ];
    };
    wireguard = {
      enable = true;
      address = "fddd:cafe::1/64";
      privateKey = builtins.readFile "${builtins.getEnv "PWD"}/wg/server.key";

      peers = [
        {
          publicKey = builtins.readFile "${builtins.getEnv "PWD"}/wg/client.pub";
          allowedIPs = [ "fddd:cafe::2/128" ];
        }
      ];
    };
  };

  # some utility packages to debug things...
  environment.systemPackages = with pkgs; [
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

