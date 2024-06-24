{ inputs, lib, pkgs, config,  ... }:
{
  services.openssh = {
    enable = true;
    # require public key authentication for better security
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  users.users."test".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGcKW01TP/gVI1KaExyrOMnnj7HUQ58Pa40r4nKGVQ8f niklas.voss@gmail.com"
  ];
 }
