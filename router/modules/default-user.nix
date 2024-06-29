{ config, options, pkgs, lib, modulesPath, ... }:
with lib;
{
  options.defaultUser = mkOption {
    type = types.str;
  };

  config = {
    users.users."${config.defaultUser}" = {
      isNormalUser = true;
      uid = 1000;
      home = "/home/${config.defaultUser}";
      extraGroups = [ "wheel" "networkmanager" "input" "video" "dialout" "docker" ];
      hashedPassword = "$7$CU..../....darl3WJb9VjRQQ/4Z9sEj.$YFZjb2Cy7ODMLvfcvSm0TF1GbOWgrxf8dQtAHrEfXU8";
    };
    services.getty.autologinUser = "${config.defaultUser}";
    security.sudo.extraRules= [{
      users = [ "${config.defaultUser}" ];
      commands = [{
        command = "ALL" ;
        options = [ "NOPASSWD" ];
      }];
    }];

  };
}
