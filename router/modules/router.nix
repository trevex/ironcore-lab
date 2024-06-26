{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.router;
  nat64Opts = {
    options = {
      tunDevice = mkOption {
        type = types.str;
        default = "nat64";
        description = "Name of the nat64 tun device.";
      };
    };
  };
  opensshOpts = {
    options = {
      enable = mkEnableOption "OpenSSH";
      authorizedKeys = mkOption {
        type = types.listOf types.singleLineStr;
        default = [];
        description = ''
          A list of verbatim OpenSSH public keys that should be added to the
          user's authorized keys. The keys are added to a file that the SSH
          daemon reads in addition to the the user's authorized_keys file.
          You can combine the `keys` and
          `keyFiles` options.
          Warning: If you are using `NixOps` then don't use this
          option since it will replace the key required for deployment via ssh.
        '';
        example = [
          "ssh-rsa AAAAB3NzaC1yc2etc/etc/etcjwrsh8e596z6J0l7 example@host"
          "ssh-ed25519 AAAAC3NzaCetcetera/etceteraJZMfk3QPfQ foo@bar"
        ];
      };
    };
  };
  wireguardPeerOpts = {
    options = {
      publicKey = mkOption {
        example = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
        type = types.str;
      };
      allowedIPs = mkOption {
        example = [ "10.192.122.3/32" "10.192.124.1/24" ];
        type = with types; listOf str;
      };
    };
  };
  wireguardOpts = {
    options = {
      enable = mkEnableOption "Wireguard";
      address = mkOption {
        example = "fc00::cafe::1";
        type = types.str;
      };
      privateKey = mkOption {
        example = "yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk=";
        type = types.str;
      };
      peers = mkOption {
        default = [];
        description = "Peers linked to the interface.";
        type = with types; listOf (submodule wireguardPeerOpts);
      };
    };
  };
in
{
  options = {
    router = {
      enable = mkEnableOption "Router";

      nat64 = mkOption {
        type = types.submodule nat64Opts;
        description = "NAT64-specific configuration.";
        default = {
          tunDevice = "nat64";
        };
      };

      externalInterface = mkOption {
        type = types.str;
        description = "Name of the external interface";
      };

      internalInterface = mkOption {
        type = types.str;
        description = "Name of the internal interface";
      };

      internalAddress = mkOption {
        type = types.str;
        description = "Internal address of the router, will be allocated with /64";
      };

      openssh = mkOption {
        type = types.submodule opensshOpts;
      };

      wireguard = mkOption {
        type = types.submodule wireguardOpts;
      };
    };
  };
  config = mkIf cfg.enable {
    # Main router configuration

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.all.accept_ra" = 0;
      "net.ipv6.conf.${cfg.externalInterface}.accept_ra" = 0;
      "net.ipv6.conf.${cfg.internalInterface}.accept_ra" = 0;
    };

    networking = {
      firewall.enable = false; # Let's keep it simple for now...
      tempAddresses = "disabled";
      nat = {
        enable = true;
        enableIPv6 = true;
        externalInterface = cfg.externalInterface;
        internalInterfaces = [ cfg.internalInterface cfg.nat64.tunDevice ];
      };
      interfaces = {
        "${cfg.internalInterface}".ipv6.addresses = [{
          address = cfg.internalAddress;
          prefixLength = 64;
        }];
      };
    };

    services.tayga = {
      enable = true;
      tunDevice = cfg.nat64.tunDevice;
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
          name = cfg.externalInterface;
          monitor = false;
          advertise = false;
        } {
          name = cfg.internalInterface;
          advertise = true;
          prefix = [{ prefix = "::/64"; }];
          rdnss = [{ servers = ["::"]; }];
          route = [{ prefix = "::/0"; } { prefix = "64:ff9b::/96"; }];
          pref64 = [{ prefix = "64:ff9b::/96"; }];
        }];
      };
    };


    # OpenSSH
    services.openssh = {
      enable = cfg.openssh.enable;
      # require public key authentication for better security
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };

    users.users."${config.defaultUser}".openssh.authorizedKeys.keys = cfg.openssh.authorizedKeys;


    # Wireguard
    networking.wg-quick.interfaces = mkIf cfg.wireguard.enable {
      wg0 = {
        address = [ "fdcc:cafe::1/64" ];
        listenPort = 51820;
        privateKey = "${cfg.wireguard.privateKey}";

        postUp = ''
          ${pkgs.iptables}/bin/ip6tables -A FORWARD -i wg0 -j ACCEPT
          ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s fdcc:cafe::1/64 -o ${cfg.internalInterface} -j MASQUERADE
        '';

        preDown = ''
          ${pkgs.iptables}/bin/ip6tables -D FORWARD -i wg0 -j ACCEPT
          ${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING -s fdcc:cafe::1/64 -o ${cfg.internalInterface} -j MASQUERADE
        '';

        peers = cfg.wireguard.peers;
      };
    };

  };
}

