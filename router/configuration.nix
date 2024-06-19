{ inputs, lib, pkgs, config,  ... }:
{
  users.users.test = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/test";
    extraGroups = [ "wheel" "networkmanager" "input" "video" "dialout" "docker" ];
    hashedPassword = "$7$CU..../....darl3WJb9VjRQQ/4Z9sEj.$YFZjb2Cy7ODMLvfcvSm0TF1GbOWgrxf8dQtAHrEfXU8";
  };
  services.getty.autologinUser = "test";
  security.sudo.extraRules= [{
      users = [ "test" ];
      commands = [{
        command = "ALL" ;
        options= [ "NOPASSWD" ];
      }];
  }];

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
  ];
}
