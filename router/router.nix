{ inputs, lib, pkgs, config,  ... }:
{
  # ens3: uplink
  # ens4: internal

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.ens3.accept_ra" = 0;
    "net.ipv6.conf.ens4.accept_ra" = 0;
  };

  networking = {
    firewall.enable = false; # Let's keep it simple for now...
    tempAddresses = "disabled";
    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = "ens3";
      internalInterfaces = [ "ens4" ];
    };
    interfaces = {
      ens4.ipv6.addresses = [{
        address = "fd00:dead:beef::2"; # first one is host, second is ours
        prefixLength = 64;
      }];
    };
    # defaultGateway6 = {
    #   address = "fe80::1";
    #   interface = "ens3";
    # };
  };

  services.tayga = {
    enable = true;
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
        name = "ens3";
        monitor = false;
        advertise = false;
      } {
        name = "ens4";
        advertise = true;
        prefix = [{ prefix = "::/64"; }];
        rdnss = [{ servers = ["::"]; }];
        route = [{ prefix = "::/0"; }];
      }];
    };
  };
}
