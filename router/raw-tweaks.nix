{ inputs, lib, pkgs, config,  ... }:
{
  boot.kernelParams = [ "console=tty0" ];

  # NOTE: The following would be required if testing install process in a VM:
  # boot.initrd.kernelModules = [
  #   "virtio_blk"
  #   "virtio_pmem"
  #   "virtio_console"
  #   "virtio_pci"
  #   "virtio_mmio"
  # ];
}
