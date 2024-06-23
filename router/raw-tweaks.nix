{ inputs, lib, pkgs, config,  ... }:
{
  boot.kernelParams = [ "console=tty0" ];
}
