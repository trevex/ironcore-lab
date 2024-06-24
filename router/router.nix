{ inputs, lib, pkgs, config, vars, ... }:
let
  tunDevice = "nat64";
in
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.${vars.externalInterface}.accept_ra" = 0;
    "net.ipv6.conf.${vars.internalInterface}.accept_ra" = 0;
  };

  networking = {
    firewall.enable = false; # Let's keep it simple for now...
    tempAddresses = "disabled";
    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = vars.externalInterface;
      internalInterfaces = [ vars.internalInterface tunDevice ];
    };
    interfaces = {
      "${vars.internalInterface}".ipv6.addresses = [{
        address = "fd00:dead:beef::2"; # in a VM ::1 will be taken by bridge
        prefixLength = 64;
      }];
    };
  };

  services.tayga = {
    enable = true;
    tunDevice = tunDevice;
    ipv4 = {
      address = "192.168.100.0";
      router = {
        address = "192.168.100.1";
      };
      pool = {
        address = "192.168.100.0";
        prefixLength = 24;
      };
    };
    ipv6 = {
      address = "2001:db8::1";
      router = {
        address = "64:ff9b::1";
      };
      pool = {
        address = "64:ff9b::";
        prefixLength = 96;
      };
    };
  };

  services.coredns = {
    enable = true;
    config = ''
      .:53 {
        forward . 8.8.8.8
        log
        errors
        cache
        dns64 {
          allow_ipv4
        }
      }
    '';
  };

  services.corerad = {
    enable = true;
    settings = {
      debug = {
        address = "localhost:9430";
        prometheus = true;
      };
      interfaces = [{
        name = vars.externalInterface;
        monitor = false;
        advertise = false;
      } {
        name = vars.internalInterface;
        advertise = true;
        prefix = [{ prefix = "::/64"; }];
        rdnss = [{ servers = ["::"]; }];
        route = [{ prefix = "::/0"; }];
        pref64 = [{ prefix = "64:ff9b::/96"; }];
      }];
    };
  };
}
