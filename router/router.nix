{ inputs, lib, pkgs, config,  ... }:
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.ens3.accept_ra" = 0;
    "net.ipv6.conf.ens4.accept_ra" = 0;
  };


  networking = {
    firewall.enable = false; # Let's keep it simple for now...
    # tempAddresses = "disabled";
    nat = {
      enable = true;
      enableIPv6 = true;
      internalInterfaces = [ "ens4" ];
      externalInterface = "ens3";
    };
  };

  # ens3: uplink
  # ens4: internal
  networking.interfaces.ens4.ipv6.addresses = [ {
    address = "fd00:dead:beef::1";
    prefixLength = 64;
  }];

  services.coredns = {
    enable = true;
    config = ''
      .:53 {
        forward . 8.8.8.8
        log
        errors
        cache
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
      interfaces = [
        {
          name = "ens4";
          advertise = true;
          prefix = [{ prefix = "::/64"; }];
          rdnss = [{ servers = ["::"]; }];
          route = [{ prefix = "::/0"; }];
          # prefix = [{ prefix = "fc00:dead:beef::/64"; }];
          # rdnss = [{ servers = ["fc00:dead:beef::1"]; }];
          # route = [{ prefix = "::/0"; }, { prefix = "fc00:dead:beef::1/64"; }];
        }
      ];
    };
  };

  # services.dnsmasq.enable = true;
  # services.dnsmasq.alwaysKeepRunning = true;
  # services.dnsmasq.settings = {
  #   log-dhcp = true;
  #   log-queries = true;
  #   log-debug = true;
  #   log-facility = "/var/log/dnsmasq.log";

  #   no-resolv = true;
  #   enable-ra = true;
  #   dhcp-authoritative = true;
  #   interface = "ens4";
  #   dhcp-range= [ "::2, constructor:ens4, ra-names, 12h" ];
  #   dhcp-option = [
  #     # "3,192.168.200.2" # Gateway
  #     # "6,192.168.200.2" # DNS servers
  #     # "option:ntp-server,192.168.200.2"
  #     # "option:dns-server,192.168.200.2"
  #   ];
  # };
}
