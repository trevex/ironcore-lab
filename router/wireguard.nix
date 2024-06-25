{ inputs, lib, pkgs, config, vars, ... }:
let
  # TODO: not oprimal handling of secrets, requires impure, but just for testenv :|
  privateKeyFile = pkgs.writeText "server.key" (builtins.readFile "${builtins.getEnv "PWD"}/wg/server.key");
in
{
  networking.wg-quick.interfaces = {
    wg0 = {
      address = [ "fdcc:cafe::1/64" ];
      listenPort = 51820;
      privateKeyFile = "${privateKeyFile}";

      postUp = ''
        ${pkgs.iptables}/bin/ip6tables -A FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s fdcc:cafe::1/64 -o ${vars.internalInterface} -j MASQUERADE
      '';

      preDown = ''
        ${pkgs.iptables}/bin/ip6tables -D FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING -s fdcc:cafe::1/64 -o ${vars.internalInterface} -j MASQUERADE
      '';

      peers = [
        {
          publicKey = builtins.readFile "${builtins.getEnv "PWD"}/wg/client.pub";
          allowedIPs = [ "fdcc:cafe::2/128" ];
        }
      ];
    };
  };
 }
