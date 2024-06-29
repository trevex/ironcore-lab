{ config, options, pkgs, lib, modulesPath, ... }:
with lib;
let
  cfg = config.hardwareConfiguration;
in
{
  options.hardwareConfiguration = {
    enable = mkOption {
      type = types.bool;
      default = true;
      example = true;
    };
  };

  config = mkIf cfg.enable {
    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = with config.boot.kernelPackages; [ ];


    fileSystems."/" =
      { device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };

    fileSystems."/boot" =
      { device = "/dev/disk/by-label/ESP";
        fsType = "vfat";
        options = [ "fmask=0022" "dmask=0022" ];
      };

    swapDevices = [ ];

    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    networking.useDHCP = lib.mkDefault true;
    # networking.interfaces.enp5s0.useDHCP = lib.mkDefault true;
    # networking.interfaces.enp5s0.4000.useDHCP = lib.mkDefault true;
    # networking.interfaces.nat64.useDHCP = lib.mkDefault true;

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # Bootloader
    boot.loader.systemd-boot.enable = false;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
    };
  };
}
